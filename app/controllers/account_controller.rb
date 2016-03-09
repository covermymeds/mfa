class AccountController < ApplicationController
   def login
      respond_to do |format|
         format.html # login.html.erb
      end
   end

   def do_login
      @user = ActiveDirectory::User.authenticate(params[:username], params[:password])

      respond_to do |format|
         if @user != nil
            session[:user] = @user.sAMAccountName.to_s
            format.html {
               flash[:notice] = "Logged in. Welcome #{@user.name}."
               redirect_to root_path
            }
         else
            format.html {
               flash[:alert] = "Bad Username or Password"
               redirect_to action: 'login'
            }
         end
      end
   end

   def logout
      session[:user] = nil

      respond_to do |format|
         format.html {
            flash[:notice] = "You have been logged out."
            redirect_to action: 'login'
         }
      end
   end

   def show
      if session[:user] and session[:user] != nil
         redirect_to mfa_path(session[:user])
      else
         redirect_to action: 'login'
      end
   end
end
