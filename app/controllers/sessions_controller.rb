class SessionsController < ApplicationController
  skip_before_action :require_login
  layout "auth"

  def new
    redirect_to root_path if logged_in?
  end

  def create
    if ActiveSupport::SecurityUtils.secure_compare(params[:password].to_s, team_password)
      reset_session
      session[:authenticated] = true
      session[:user_token] = SecureRandom.hex(16)
      session[:user_name] = params[:name].to_s.strip.first(40).presence
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
