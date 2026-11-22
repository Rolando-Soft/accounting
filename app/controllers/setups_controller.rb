# One-time first-run setup: creates the single admin user a fresh install
# needs to log in at all. Only reachable while no User exists yet — once
# one has been created (here or via the console), this becomes permanently
# inaccessible, same as "setup has already run" in other self-hosted apps.
class SetupsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_already_set_up

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_if_already_set_up
      redirect_to new_session_path, alert: "Setup has already been completed." if User.exists?
    end

    def user_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end
end
