class CommentsController < ApplicationController
  def create
    card = Card.find(params[:card_id])
    comment = card.comments.new(body: params.dig(:comment, :body), author_name: current_user_name, author_token: current_user_token)
    if comment.save
      redirect_to card.board, status: :see_other
    else
      redirect_to card.board, alert: comment.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.destroy
    redirect_to comment.card.board, status: :see_other
  end
end
