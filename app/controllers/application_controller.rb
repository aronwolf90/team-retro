class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_user_token
  before_action :require_login

  helper_method :current_user_name, :current_user_token, :logged_in?, :team_login?, :name_missing?, :can_access_board?, :accessible_boards

  private

  def team_password
    Rails.application.config.x.team_password
  end

  # Logged in with the team password.
  def team_login?
    session[:authenticated] == true
  end

  # Logged in with the team password or at least one board password.
  def logged_in?
    team_login? || unlocked_boards.any?
  end

  def require_login
    return if logged_in?
    redirect_to new_session_path, alert: "Please log in to see your team's retro boards."
  end

  def require_team_login
    return if team_login?
    redirect_to new_session_path, alert: "Please log in with the team password."
  end

  # A board with its own password opens only with that password, never with the team password.
  def can_access_board?(board)
    board.password_protected? ? board_unlocked?(board) : team_login?
  end

  def require_board_access
    return if can_access_board?(@board)

    if @board.password_protected?
      redirect_to new_board_unlock_path(@board)
    else
      require_team_login
    end
  end

  def accessible_boards
    @accessible_boards ||= begin
      unlocked = Board.where(id: unlocked_boards.keys).select { |board| board_unlocked?(board) }
      scope = Board.where(id: unlocked.map(&:id))
      team_login? ? scope.or(Board.where(password_digest: nil)) : scope
    end
  end

  # Board id => password salt at unlock time, so changing the password locks everyone out again.
  def unlocked_boards
    session[:unlocked_boards] || {}
  end

  def board_unlocked?(board)
    salt = unlocked_boards[board.id.to_s]
    board.password_protected? && salt.present? && ActiveSupport::SecurityUtils.secure_compare(salt, board.password_salt)
  end

  def remember_board_unlock(board)
    session[:unlocked_boards] = unlocked_boards.merge(board.id.to_s => board.password_salt)
  end

  # New session id on every login against session fixation, keeping who the user is and what they unlocked.
  def renew_session
    kept = session.to_hash.slice("authenticated", "user_token", "user_name", "unlocked_boards", "team_name")
    reset_session
    session.update(kept)
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
