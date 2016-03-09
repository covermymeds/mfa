require 'enviro'
require 'rotp'
require 'google-qr'

class ActiveDirectory::User < ActiveLdap::Base
   include Authority::UserAbilities
   include Authority::Abilities

   ldap_mapping :dn_attribute => 'sAMAccountName', :prefix => ''

   self.authorizer_name = 'UserAuthorizer'

   ActiveLdap::Base.setup_connection(
      :host => Settings.ldap.host,
      :port => Settings.ldap.port,
      :base => Settings.ldap.base,
      :bind_dn => Settings.ldap.bind_dn,
      :method => :ssl,
      :password_block => Proc.new { Settings.ldap.bind_pw },
      :allow_anonymous => false )


   def self.authenticate(user_name, password)
      # See if we can find the user in ldap

      if user_name == nil or password == nil
         return nil
      end

      result = self.find(user_name)

      # If we cant find the user, bail
      if result.nil?
         return nil
      end

      # Grab the DN
      dn = result.dn.to_s

      # Now attempt to bind as the DN
      ldap = Net::LDAP.new(
         :host       => Settings.ldap.host,
         :port       => Settings.ldap.port,
         :encryption => :simple_tls,
         :auth       => {
            :method   => :simple,
            :username => dn,
            :password => password
         }
      )

      if !ldap.bind
         return nil
      end

      # Return the AD object
      return result
   end

   def google_label_name
      if self.mail != nil and self.mail != ''
         self.mail
      else
         "#{self.sAMAccountName}@#{Settings.mailer.to_domain}"
      end
   end

   def admin?
      if self.memberof == nil
         false
      else
         return self.memberof.include?(Settings.ldap.admin_group)
      end
   end

   def set_google_secret
      self.google_secret = ROTP::Base32.random_base32
      self.save
   end

   def set_mfa_active
      self.mfa_active = true
      self.save
   end

   def set_mfa_inactive
      self.set_google_secret
      self.mfa_active = false
      self.save
   end

   def google_qr_uri
      return GoogleQR.new(
         :data => ROTP::TOTP.new(self.google_secret, :issuer => self.google_issuer).provisioning_uri(self.google_label_name),
         :size => self.google_qr_size).to_s
   end

   def google_issuer
      Settings.org_name
   end

   def google_qr_size
      "200x200"
   end

   def google_secret
      begin
         self.encrypt_start
         return @encryptor.decrypt_and_verify(self[Settings.ldap.totp_field])
      rescue
         nil
      end
   end

   def google_secret=(value)
      begin
         self.encrypt_start
         self[Settings.ldap.totp_field] = @encryptor.encrypt_and_sign(value)
      rescue
         return false
      end
   end

   def google_authentic?(value)
      ROTP::TOTP.new(self.google_secret).verify_with_drift(value, 6)
   end

   def mfa_active
      begin
         return eval(self[Settings.ldap.enabled_field])
      rescue
         return false
      end
   end

   def mfa_active?
      return mfa_active
   end

   def mfa_active=(value)
      self[Settings.ldap.enabled_field] = self.google_secret != nil ? value.to_s : 'false'
   end

	def locked?
		return ((self['userAccountControl'] & 2) != 0 or self['lockoutTime'].to_i > 0)
	end

   def id
      if caller_locations(1,1)[0].label == 'compute_dn'
         return super
      else
         return self.sAMAccountName
      end
   end

   protected 

   def encrypt_start 
      if @encryptor == nil
         passphrase = ActiveSupport::KeyGenerator.new(Settings.totp_pass).generate_key(Settings.totp_salt)
         @encryptor = ActiveSupport::MessageEncryptor.new(passphrase)
      end
   end
end
