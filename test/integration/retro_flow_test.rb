require "test_helper"

class RetroFlowTest < ActionDispatch::IntegrationTest
  test "requires the team password" do
    get boards_path
    assert_redirected_to new_session_path

    post session_path, params: { password: "wrong", name: "Sam" }
    assert_response :unprocessable_entity

    post session_path, params: { password: "retro", name: "Sam" }
    assert_redirected_to root_path
    get boards_path
    assert_response :success
  end

  test "asks for a name when none is stored" do
    post session_path, params: { password: "retro", name: "" }
    get boards_path
    assert_select "dialog#name-dialog[data-modal-required]"

    patch profile_path, params: { name: "Sam" }
    get boards_path
    assert_select "dialog#name-dialog[data-modal-required]", count: 0
    assert_select "button", text: /Sam/
  end

  test "full retro: cards, votes, comments, move, merge, timer, export" do
    login
    post boards_path, params: { board: { name: "Sprint 1", max_votes: 2 } }
    board = Board.last
    assert_redirected_to board

    post board_cards_path(board), params: { card: { lane: "went_well", content: "Shipped it" } }
    post board_cards_path(board), params: { card: { lane: "went_well", content: "Good pairing" } }
    post board_cards_path(board), params: { card: { lane: "to_improve", content: "Flaky CI" } }
    post board_cards_path(board), params: { card: { lane: "how_is_everyone", content: "Tired but fine" } }
    post board_cards_path(board), params: { card: { lane: "action_items", content: "Kim: investigate flaky specs" } }
    first, second, third = board.cards.order(:id).first(3)
    assert_equal "Sam", first.author_name

    # votes are capped by max_votes
    post card_votes_path(first)
    post card_votes_path(first)
    post card_votes_path(second)
    assert_equal 2, board.votes.count
    follow_redirect!
    assert_match "used all your 2 votes", flash[:alert]

    delete card_votes_path(first)
    assert_equal 1, first.votes.count

    post card_comments_path(first), params: { comment: { body: "Let's keep doing this" } }
    assert_equal 1, first.comments.count

    patch move_card_path(third), params: { column: "went_well", position: 0 }, as: :json
    assert_response :no_content
    assert_equal %w[Flaky\ CI Shipped\ it Good\ pairing], board.cards_in(:went_well).map(&:content)

    post merge_card_path(second), params: { target_id: first.id }, as: :json
    assert_response :no_content
    assert_equal first.id, second.reload.parent_id

    post board_timer_path(board, minutes: 5)
    assert board.reload.timer_running?
    delete board_timer_path(board)
    assert_nil board.reload.timer_ends_at

    patch board_path(board), params: { board: { hidden_lanes: [ "", "to_improve" ], sort_by: "votes" } }
    assert_equal [ "to_improve" ], board.reload.hidden_lanes
    get board_path(board)
    assert_response :success
    assert_select ".banner", text: /To Improve/

    patch toggle_hidden_board_path(board, lane: "went_well")
    assert_equal %w[to_improve went_well], board.reload.hidden_lanes.sort
    patch toggle_hidden_board_path(board, lane: "to_improve")
    assert_equal %w[went_well], board.reload.hidden_lanes
    patch toggle_hidden_board_path(board, lane: "bogus")
    assert_equal %w[went_well], board.reload.hidden_lanes

    post boards_path, params: { board: { name: "Sprint 2" } }
    follow_redirect!
    assert_match "1 action item from “Sprint 1”", flash[:notice]
    assert_equal [ "Kim: investigate flaky specs" ], Board.last.cards_in(:last_time).map(&:content)
    Board.last.destroy

    get export_board_path(board)
    assert_response :success
    assert_match "Went Well,Shipped it,1,Sam,Good pairing", response.body
    assert_match "How is everyone?,Tired but fine", response.body

    delete board_path(board)
    assert_equal 0, Board.count
  end

  test "hidden columns blur other people's cards but not your own or other columns" do
    login
    board = Board.create!(name: "Retro", hidden_lanes: [ "went_well" ])
    board.cards.create!(lane: :went_well, content: "Secret from Bob", author_token: "someone-else")
    board.cards.create!(lane: :to_improve, content: "Visible from Bob", author_token: "someone-else")
    post board_cards_path(board), params: { card: { lane: "went_well", content: "My own card" } }

    get board_path(board)
    assert_select ".card--hidden", count: 1
    assert_no_match "Secret from Bob", response.body
    assert_match "Visible from Bob", response.body
    assert_match "My own card", response.body
  end

  private

  def login(name: "Sam")
    post session_path, params: { password: "retro", name: name }
  end
end
