require 'net/http'

class MfaMailer < ActionMailer::Base
  default from: Settings.mail_from_address

  def mfa_email(user)
     @user = user

     attachments.inline['qrcode.jpg'] = Net::HTTP.get(URI(@user.google_qr_uri))

     mail(to: @user.mail, subject: "Your QR Code For #{Settings.org_name} MFA")
  end
end
