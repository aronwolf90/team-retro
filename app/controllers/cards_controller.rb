class CardsController < ApplicationController
  before_action :set_card, except: :create

  def create
    board = Board.find(params[:board_id])
    card = board.cards.new(card_params.merge(author_name: current_user_name, author_token: current_user_token))
    if card.save
      redirect_to board, status: :see_other
    else
      redirect_to board, alert: card.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def update
    if @card.update(params.require(:card).permit(:content))
      redirect_to @card.board, status: :see_other
    else
      redirect_to @card.board, alert: @card.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @card.destroy
    redirect_to @card.board, status: :see_other
  end

  # PATCH /cards/:id/move  { column: "to_improve", position: 2 }
  def move
    @card.unmerge! if @card.parent_id
    @card.move_to!(params[:column], params[:position])
    head :no_content
  end

  # POST /cards/:id/merge  { target_id: 42 }  -> merges this card into target
  def merge
    target = @card.board.cards.roots.find(params[:target_id])
    target.merge!(@card)
    head :no_content
  end

  def unmerge
    @card.unmerge!
    redirect_to @card.board, status: :see_other
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:content, :lane)
  end
end
