class MfaController < ApplicationController
   authorize_actions_for ActiveDirectory::User
   authority_actions :regen => 'update', :email => 'update'

   # GET /mfa
   def index
      if @current_user.admin?
         redirect_to root_path
      end

      @users = ActiveDirectory::User.order(:username)
      
      respond_to do |format|
         format.html { @users_page = Kaminari.paginate_array(@users).page(params[:page]) }
      end
   end

   # GET /mfa/:id
   def show
      @user = ActiveDirectory::User.find(params[:id])

      # Generate an mfa secret if there isnt one
      begin
         if !@user.google_secret or @user.google_secret == ''
            @user.set_google_secret()
            @user.save
         end
      rescue
         flash[:alert] = "There was a problem creating a token for this user."
      end
         

      authorize_action_for(@user)

      respond_to do |format|
         format.html # show.html.erb
      end
   end

   # PUT /mfa/:id/regen
   def regen
      @user = ActiveDirectory::User.find(params[:id])
      @user.set_google_secret()

      redirect_to :action => 'show'
   end

   # PUT /mfa/:id/email
   def email
      @user = ActiveDirectory::User.find(params[:id])

      MfaMailer.mfa_email(@user).deliver

      redirect_to :action => 'show'
   end

   # POST /mfa/:id
   def update 
      @user = ActiveDirectory::User.find(params[:id])
      
      respond_to do |format|
         if @user.google_authentic?(params[:verify_code])
            if @user.mfa_active?
               format.html {
                  flash[:notice] = "Token is valid."
                  redirect_to :action => 'show'
               }
            elsif @user.set_mfa_active()
               format.html {
                  flash[:notice] = "Token has been activated."
                  redirect_to :action => 'show'
               }
            else
               format.html {
                  flash[:alert] = "There was a problem while activating token."
                  redirect_to :action => 'show'
               }
            end
         else
            format.html {
               flash[:alert] = "Invalid second factor key, please try again."
               redirect_to :action => 'show'
            }
         end
      end
   end

   # DELETE /mfa/:id
   def destroy
      @user = ActiveDirectory::User.find(params[:id])

      if @user.set_mfa_inactive()
         flash[:notice] = "Token has been revoked successfully."
         redirect_to :action => 'show'
      else
         flash[:alert] = "There was a problem committing changes."
         redirect_to :action => 'show'
      end
   end
end
