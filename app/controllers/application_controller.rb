class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :ensure_user_token
  before_action :require_login

  helper_method :current_user_name, :current_user_token, :logged_in?, :name_missing?

  private

  def team_password
    Rails.application.config.x.team_password
  end

  def logged_in?
    session[:authenticated] == true
  end

  def require_login
    return if logged_in?
    redirect_to new_session_path, alert: "Please log in to see your team's retro boards."
  end

  def ensure_user_token
    session[:user_token] ||= SecureRandom.hex(16)
  end

  def current_user_token
    session[:user_token]
  end

  def current_user_name
    session[:user_name].presence
  end

  def name_missing?
    logged_in? && current_user_name.blank?
  end
end
