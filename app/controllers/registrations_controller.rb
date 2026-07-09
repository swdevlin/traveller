class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action { redirect_to root_path if authenticated? }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.require(:user).permit(:email_address, :password, :password_confirmation))
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      render :new, status: :unprocessable_entity
    end
  end
end
