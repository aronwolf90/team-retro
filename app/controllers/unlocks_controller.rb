class UnlocksController < ApplicationController
  skip_before_action :require_login
  before_action :set_board
  before_action :redirect_if_accessible
  rate_limit to: 10, within: 3.minutes, only: :create, by: -> { [ request.remote_ip, params[:board_id] ] },
    with: -> { redirect_to new_board_unlock_path(@board), alert: "Too many attempts. Please try again in a few minutes." }
  layout "auth"

  def new
  end

  def create
    if @board.authenticate(params[:password].to_s)
      renew_session
      remember_board_unlock(@board)
      name = params[:name].to_s.strip.first(40).presence
      session[:user_name] = name if name
      redirect_to @board, notice: "Welcome to “#{@board.name}”!"
    else
      flash.now[:alert] = "That board password is not right."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_board
    @board = Board.find(params[:board_id])
  end

  # Boards without their own password use the team login instead.
  def redirect_if_accessible
    redirect_to @board unless @board.password_protected? && !can_access_board?(@board)
  end
end
