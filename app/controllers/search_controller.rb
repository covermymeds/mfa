class SearchController < ApplicationController
   def index
      if !@current_user.admin?
         flash[:alert] = "You are not authorized to perform this action!"
         redirect_to root_path
      end

      @users = Array.new()
      if params[:search] != nil
         ad_results = ActiveDirectory::User.search(:filter => "(&(|(name=#{params[:search]})(sAMAccountName=#{params[:search]}))(objectClass=user))")
         ad_results.each do |r|
            begin
               u = ActiveDirectory::User.find(r[1]['sAMAccountName'].first)
            end
            @users << u
         end
      else
         flash[:alert] = "Search string must be given."
      end
   end
end
