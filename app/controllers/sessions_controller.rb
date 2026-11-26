class SessionsController < ApplicationController
  skip_before_action :require_login
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Too many attempts. Please try again in a few minutes." }
  layout "auth"

  def new
    redirect_to root_path if team_login?
  end

  def create
    if ActiveSupport::SecurityUtils.secure_compare(params[:password].to_s, team_password)
      renew_session
      session[:authenticated] = true
      name = params[:name].to_s.strip.first(40).presence
      session[:user_name] = name if name
      redirect_to root_path, notice: "Welcome to the team retro!"
    else
      flash.now[:alert] = "That team password is not right."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "You have been logged out."
  end
end
