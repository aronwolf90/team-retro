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

  test "full retro: cards, votes, reactions, move, merge, timer, follow-up board" do
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

    post card_reactions_path(first, emoji: "🎉")
    post card_reactions_path(first, emoji: "🎉")
    assert_equal 0, first.reactions.count
    post card_reactions_path(first, emoji: "❤️")
    post card_reactions_path(first, emoji: "💩")
    assert_equal [ "❤️" ], first.reactions.pluck(:emoji)
    get board_path(board)
    assert_select ".reaction--mine[title='Sam']", text: /❤️\s*1/

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
    next_board = Board.last
    assert_empty next_board.cards
    get board_path(next_board)
    assert_select "#import-menu turbo-frame[src=?]", import_board_path(next_board)
    get import_board_path(next_board)
    assert_select "select option[selected]", text: /Sprint 1/
    assert_select "input[type=checkbox][name='card_ids[]'][checked]", count: 1
    assert_select ".import-picker__card", text: /Kim: investigate flaky specs/
    carried = board.cards.create!(lane: :last_time, content: "Carried over")
    get import_board_path(next_board)
    assert_select "input[name='card_ids[]'][value=?]:not([checked])", carried.id.to_s
    assert_select "input[name='card_ids[]'][checked]", count: 1
    carried.destroy
    post import_action_items_board_path(next_board), params: { source_board_id: board.id }
    follow_redirect!
    assert_match "Select at least one card", flash[:alert]
    action_item = board.cards.find_by!(content: "Kim: investigate flaky specs")
    post import_action_items_board_path(next_board), params: { source_board_id: board.id, card_ids: [ action_item.id, first.id ] }
    follow_redirect!
    assert_match "Imported 1 card from “Sprint 1”", flash[:notice]
    assert_equal [ "Kim: investigate flaky specs" ], next_board.cards_in(:last_time).map(&:content)
    post import_action_items_board_path(next_board), params: { source_board_id: next_board.id }
    assert_response :not_found
    next_board.destroy

    delete board_path(board)
    assert_equal 0, Board.count
  end

  test "the icebreaker column is optional per board" do
    login
    post boards_path, params: { board: { name: "Retro" } }
    board = Board.last
    get board_path(board)
    assert_select "[data-column=icebreaker]", count: 0

    patch board_path(board), params: { board: { icebreaker: "1" } }
    post board_cards_path(board), params: { card: { lane: "icebreaker", content: "Favourite snack?" } }
    get board_path(board)
    assert_select "section[data-column=icebreaker] .card__text", text: "Favourite snack?"
  end

  test "the how is everyone column is on by default and can be turned off" do
    login
    post boards_path, params: { board: { name: "Retro" } }
    board = Board.last
    assert board.how_is_everyone?
    get board_path(board)
    assert_select "section[data-column=how_is_everyone]", count: 1

    patch board_path(board), params: { board: { how_is_everyone: "0" } }
    get board_path(board)
    assert_select "section[data-column=how_is_everyone]", count: 0
    assert_select "section[data-column=went_well]", count: 1
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
