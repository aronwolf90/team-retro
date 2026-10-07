class BoardsController < ApplicationController
  before_action :set_board, only: %i[show edit update destroy toggle_hidden import import_action_items]

  def index
    @boards = Board.left_joins(:cards).group("boards.id")
      .select("boards.*, COUNT(cards.id) AS cards_count")
      .order(created_at: :desc)
  end

  def show
    @columns = @board.columns.map { |column| [ column, @board.cards_in(column[:key]) ] }
    @votes_left = @board.votes_left_for(current_user_token)
  end

  def new
    @board = Board.new(name: "Sprint retro #{Date.current.strftime('%b %-d')}", max_votes: 6)
  end

  def create
    @board = Board.new(board_params)
    if @board.save
      redirect_to @board, notice: "Board created. Share the link with your team!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @board.update(board_params)
      redirect_to @board, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /boards/:id/toggle_hidden?lane=to_improve
  def toggle_hidden
    @board.toggle_lane_hidden!(params[:lane])
    redirect_to @board, status: :see_other
  end

  def import
    @sources = @board.import_sources
    @source = params[:source_board_id].present? ? @sources.find(params[:source_board_id]) : @sources.first
    render layout: false
  end

  def import_action_items
    source = @board.import_sources.find(params[:source_board_id])
    imported = @board.import_cards_from(source, params[:card_ids])
    if imported.zero?
      redirect_to @board, alert: "Select at least one card to import.", status: :see_other
    else
      redirect_to @board, notice: "Imported #{imported} #{'card'.pluralize(imported)} from “#{source.name}”.", status: :see_other
    end
  end

  def destroy
    @board.destroy
    redirect_to boards_path, notice: "Board deleted.", status: :see_other
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :max_votes, :hide_votes, :icebreaker, :how_is_everyone, :sort_by, hidden_lanes: [])
  end
end
