class AuthenticateController < ApplicationController
   skip_before_action :verify_authenticity_token

   # POST /authenticate/:id
   def update
		@result = Hash.new()
		@result['status'] = 'FAIL'
		@result['message'] = 'Invalid credentials'
     
      if !params[:id] or !params[:password] or !params[:mfa] or !params[:mfa_only]
         @result['status'] = 'FAIL'
         @result['message'] = 'Expected argument not given'
			logger.warn "AUTH: Missing arguments for #{params[:id]}"
      else
			if params[:mfa_only]
				# Find the user, verify they arent locked/disabled, and then mfa them
				@user = ActiveDirectory::User.find(params[:id])

				if @user
					if !@user.locked? and @user.google_authentic?(params[:mfa])
						@result['status'] = 'SUCCESS'
						@result['message'] = 'MFA successful'
						logger.warn "AUTH: Successful auth for #{params[:id]}"
					else
						logger.warn "AUTH: Failed auth #{params[:id]} - Failed MFA"
					end
				else
					logger.warn "AUTH: Failed auth #{params[:id]} - Unable to find user"
				end
			else
				# Do a full authentication attempt against the user
				@user = ActiveDirectory::User.authenticate(params[:id], params[:password])
				
				if @user
					if @user.google_authentic?(params[:mfa])
						@result['status'] = 'SUCCESS'
						@result['message'] = 'MFA successful'
						logger.warn "AUTH: Successful auth for #{params[:id]}"
					else
						logger.warn "AUTH: Failed auth #{params[:id]} - Failed MFA"
					end
				else
					logger.warn "AUTH: Failed auth #{params[:id]} - Unable to find user or failed password"
				end
			end
		end

		logger.warn "AUTH: #{params[:id]} - #{@result}"
      respond_to do |format|
         format.json { render json: @result }
      end
   end
end
