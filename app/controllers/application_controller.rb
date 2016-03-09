class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :set_current_user

  def set_current_user
     @current_user = current_user
  end

  def current_user
     begin
        ActiveDirectory::User.find(session[:user])
     rescue
        ActiveDirectory::User.new()
     end
  end

  def authority_forbidden(error)
     if session[:user] != nil && session[:user] != ''
        redirect_to root_path, :alert => 'You are not authorized.'
     else
        redirect_to :controller => 'account', :action => 'login', :alert => 'You must be logged in to continue.'
     end
  end
end
