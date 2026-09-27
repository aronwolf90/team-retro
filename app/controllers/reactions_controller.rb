class ReactionsController < ApplicationController
  def create
    card = Card.find(params[:card_id])
    existing = card.reactions.find_by(emoji: params[:emoji], user_token: current_user_token)
    if existing
      existing.destroy
    else
      card.reactions.create(emoji: params[:emoji], user_name: current_user_name, user_token: current_user_token)
    end
    redirect_to card.board, status: :see_other
  end
end
