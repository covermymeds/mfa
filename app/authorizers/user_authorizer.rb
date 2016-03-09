# Other authorizers should subclass this one
class UserAuthorizer < ApplicationAuthorizer

  # Any class method from Authority::Authorizer that isn't overridden
  # will call its authorizer's default method.
  #
  # @param [Symbol] adjective; example: `:creatable`
  # @param [Object] user - whatever represents the current user in your app
  # @return [Boolean]
  def self.default(adjective, user)

    if user.sAMAccountName == nil
       false
    else
       true
    end
  end

  def readable_by?(user)
     # Allow a user to futz with themselves, otherwise only let admins play with others
     resource != nil and (resource == user or user.admin?)
  end
end
