class ReactionsController < ApplicationController
  skip_before_action :require_login
  before_action :set_card
  before_action :require_board_access

  def create
    existing = @card.reactions.find_by(emoji: params[:emoji], user_token: current_user_token)
    if existing
      existing.destroy
    else
      @card.reactions.create(emoji: params[:emoji], user_name: current_user_name, user_token: current_user_token)
    end
    redirect_to @board, status: :see_other
  end

  private

  def set_card
    @card = Card.find(params[:card_id])
    @board = @card.board
  end
end
