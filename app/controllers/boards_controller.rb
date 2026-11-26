class BoardsController < ApplicationController
  BOARD_ACTIONS = %i[show edit update destroy toggle_hidden reset_votes import import_action_items].freeze

  skip_before_action :require_login, only: BOARD_ACTIONS
  before_action :require_team_login, only: %i[new create]
  before_action :set_board, only: BOARD_ACTIONS
  before_action :require_board_access, only: BOARD_ACTIONS
  before_action :set_import_sources, only: %i[new create]

  def index
    @boards = (team_login? ? Board.all : accessible_boards).left_joins(:cards).group("boards.id")
      .select("boards.*, COUNT(cards.id) AS cards_count")
      .order(created_at: :desc)
  end

  def show
    @columns = @board.columns.map { |column| [ column, @board.cards_in(column[:key]) ] }
    @votes_left = @board.votes_left_for(current_user_token)
  end

  def new
    @board = Board.new(name: "Sprint retro #{Date.current.strftime('%b %-d')}", max_votes: 6,
      hidden_lanes: %w[how_is_everyone went_well to_improve])
    @import_from_board_id = @import_sources.first&.id
  end

  def create
    @board = Board.new(board_params)
    @import_from_board_id = params[:import_from_board_id].presence
    source = @import_sources.find(@import_from_board_id) if @import_from_board_id
    if @board.save
      remember_board_unlock(@board) if @board.password_protected?
      imported = source ? @board.import_action_items_from(source) : 0
      notice = imported.zero? ? "Board created." : "Board created with #{imported} #{'action item'.pluralize(imported)} from “#{source.name}”."
      redirect_to @board, notice: "#{notice} Share the link with your team!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @board.update(board_params)
      remember_board_unlock(@board) if @board.password_protected?
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

  def reset_votes
    @board.reset_votes!
    redirect_to @board, notice: "All votes have been reset.", status: :see_other
  end

  def import
    @sources = @board.import_sources(accessible_boards)
    @source = params[:source_board_id].present? ? @sources.find(params[:source_board_id]) : @sources.first
    render layout: false
  end

  def import_action_items
    source = @board.import_sources(accessible_boards).find(params[:source_board_id])
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

  # Only boards the user can open, so creating a board can't copy cards out of a locked one.
  def set_import_sources
    @import_sources = accessible_boards.order(created_at: :desc)
  end

  def board_params
    params.require(:board).permit(:name, :max_votes, :hide_votes, :icebreaker, :how_is_everyone, :sort_by, :password, :remove_password, hidden_lanes: [], column_titles: Board::LANE_KEYS)
  end
end
