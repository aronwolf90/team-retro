class TimersController < ApplicationController
  before_action :set_board

  # Start a timer for N minutes.
  def create
    minutes = params[:minutes].to_i.clamp(1, 120)
    @board.update!(timer_ends_at: minutes.minutes.from_now)
    redirect_to @board, status: :see_other
  end

  # Add one minute to the running timer.
  def update
    base = @board.timer_running? ? @board.timer_ends_at : Time.current
    @board.update!(timer_ends_at: base + 1.minute)
    redirect_to @board, status: :see_other
  end

  def destroy
    @board.update!(timer_ends_at: nil)
    redirect_to @board, status: :see_other
  end

  private

  def set_board
    @board = Board.find(params[:board_id])
  end
end
