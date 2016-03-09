class ReportController < ApplicationController
   # GET /report
   def index
      @users = ActiveDirectory::User.all.select {|u| u.respond_to?('userAccountControl') and u.userAccountControl == 512}
      @active_users = @users.select{|u| u.mfa_active? }
      @num_active_users = @active_users.count
      @num_inactive_users = @users.count - @num_active_users
   end

   def inactive
      @users = ActiveDirectory::User.all.select {|u| u.respond_to?('userAccountControl') and u.userAccountControl == 512}
      @inactive_users = @users.select{|u| u.mfa_active? == false }
   end
end
