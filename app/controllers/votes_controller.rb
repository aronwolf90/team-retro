class VotesController < ApplicationController
  skip_before_action :require_login
  before_action :set_card
  before_action :require_board_access

  def create
    board = @card.board
    if board.votes_left_for(current_user_token) > 0
      @card.votes.create!(voter_token: current_user_token)
      redirect_to board, status: :see_other
    else
      redirect_to board, alert: "You have used all your #{board.max_votes} votes.", status: :see_other
    end
  end

  def destroy
    @card.votes.where(voter_token: current_user_token).order(:created_at).last&.destroy
    redirect_to @card.board, status: :see_other
  end

  private

  def set_card
    @card = Card.find(params[:card_id])
    @board = @card.board
  end
end
