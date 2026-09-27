require "csv"

class BoardsController < ApplicationController
  before_action :set_board, only: %i[show edit update destroy export toggle_hidden]

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

  def destroy
    @board.destroy
    redirect_to boards_path, notice: "Board deleted.", status: :see_other
  end

  def export
    csv = CSV.generate do |rows|
      rows << [ "Column", "Card", "Votes", "Author", "Merged cards", "Comments", "Created at" ]
      Board::COLUMNS.each do |column|
        @board.cards_in(column[:key]).each do |card|
          rows << [
            column[:title],
            card.content,
            card.votes_count,
            card.author_name,
            card.children.map(&:content).join(" | "),
            card.comments.map { |c| "#{c.author_name}: #{c.body}" }.join(" | "),
            card.created_at.iso8601
          ]
        end
      end
    end
    send_data csv, filename: "#{@board.name.parameterize}-#{Date.current}.csv", type: "text/csv"
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :context, :max_votes, :hide_votes, :hide_authors, :sort_by, hidden_lanes: [])
  end
end
