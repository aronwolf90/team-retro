class BoardsController < ApplicationController
  before_action :set_board, only: %i[show edit update destroy toggle_hidden]

  def index
    @boards = Board.left_joins(:cards).group("boards.id")
      .select("boards.*, COUNT(cards.id) AS cards_count")
      .order(created_at: :desc)
  end

  def show
    @columns = Board::COLUMNS.map { |column| [ column, @board.cards_in(column[:key]) ] }
    @votes_left = @board.votes_left_for(current_user_token)
  end

  def new
    @board = Board.new(name: "Sprint retro #{Date.current.strftime('%b %-d')}", max_votes: 6)
  end

  def create
    @board = Board.new(board_params)
    if @board.save
      previous = @board.previous
      imported = @board.import_action_items_from(previous)
      notice = "Board created. Share the link with your team!"
      notice = "Board created with #{imported} action #{'item'.pluralize(imported)} from “#{previous.name}”." if imported > 0
      redirect_to @board, notice: notice
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

  def destroy
    @board.destroy
    redirect_to boards_path, notice: "Board deleted.", status: :see_other
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :context, :max_votes, :hide_votes, :hide_authors, :sort_by, hidden_lanes: [])
  end
end
