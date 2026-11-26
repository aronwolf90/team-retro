require "test_helper"

class BoardPasswordTest < ActionDispatch::IntegrationTest
  setup do
    @secret = Board.create!(name: "Leads retro", password: "s3cret")
    @card = @secret.cards.create!(lane: :went_well, content: "Secret card")
    @open = Board.create!(name: "Team retro")
  end

  test "the team password does not open a board with its own password" do
    login
    get board_path(@secret)
    assert_redirected_to new_board_unlock_path(@secret)

    post board_cards_path(@secret), params: { card: { lane: "went_well", content: "Sneaky" } }
    assert_redirected_to new_board_unlock_path(@secret)
    patch board_path(@secret), params: { board: { remove_password: "1" } }
    post card_votes_path(@card)
    post card_reactions_path(@card, emoji: "🎉")
    patch move_card_path(@card), params: { column: "to_improve", position: 0 }, as: :json
    delete card_path(@card)
    post board_timer_path(@secret, minutes: 5)
    delete board_path(@secret)

    assert @secret.reload.password_protected?
    assert_equal [ "Secret card" ], @secret.cards.pluck(:content)
    assert_equal "went_well", @card.reload.lane
    assert_equal 0, @card.votes.count + @card.reactions.count
    assert_nil @secret.timer_ends_at
  end

  test "the team list shows locked boards with a lock but no content" do
    login
    get boards_path
    assert_select "a[href=?]", new_board_unlock_path(@secret), text: /🔒\s*Leads retro/
    assert_select "a[href=?]", board_path(@secret), count: 0
    assert_select "a[href=?]", board_path(@open)
  end

  test "the board password alone opens only that board" do
    get board_path(@secret)
    assert_redirected_to new_board_unlock_path(@secret)

    post board_unlock_path(@secret), params: { password: "wrong", name: "Kim" }
    assert_response :unprocessable_entity

    post board_unlock_path(@secret), params: { password: "s3cret", name: "Kim" }
    assert_redirected_to board_path(@secret)
    follow_redirect!
    assert_match "Secret card", response.body

    post board_cards_path(@secret), params: { card: { lane: "to_improve", content: "From Kim" } }
    assert_equal "Kim", @secret.cards.find_by!(content: "From Kim").author_name

    get boards_path
    assert_select ".board-item", count: 1
    assert_select ".board-item__name", text: /Leads retro/
    assert_select "a[href=?]", new_board_path, count: 0

    get board_path(@open)
    assert_redirected_to new_session_path
    get new_board_path
    assert_redirected_to new_session_path
  end

  test "team login keeps unlocked boards" do
    post board_unlock_path(@secret), params: { password: "s3cret", name: "Kim" }
    login
    get board_path(@secret)
    assert_response :success
    get board_path(@open)
    assert_response :success
  end

  test "setting a password keeps the editor in and changing it locks others out" do
    login
    patch board_path(@open), params: { board: { password: "first" } }
    assert @open.reload.password_protected?
    get board_path(@open)
    assert_response :success

    other = open_session
    other.post session_path, params: { password: "retro", name: "Bob" }
    other.post board_unlock_path(@open), params: { password: "first" }
    other.get board_path(@open)
    assert_equal 200, other.response.status

    patch board_path(@open), params: { board: { password: "second" } }
    get board_path(@open)
    assert_response :success
    other.get board_path(@open)
    assert_equal new_board_unlock_path(@open), URI(other.response.location).path

    patch board_path(@open), params: { board: { password: "", name: "Renamed" } }
    assert @open.reload.authenticate("second")

    patch board_path(@open), params: { board: { remove_password: "1" } }
    assert_not @open.reload.password_protected?
    other.get board_path(@open)
    assert_equal 200, other.response.status
  end

  test "creating a board with a password" do
    login
    get new_board_path
    assert_select "[data-controller=password-generator] input[type=password][name='board[password]']"
    assert_select "[data-controller=password-generator] button[data-action='password-generator#generate']", text: "Generate"

    post boards_path, params: { board: { name: "Private", password: "pw" } }
    board = Board.last
    assert board.authenticate("pw")
    assert_redirected_to board
    follow_redirect!
    assert_response :success
  end

  test "rejects passwords longer than bcrypt allows" do
    board = Board.new(name: "Long", password: "x" * 73)
    assert_not board.valid?
    assert board.errors.added?(:password, :password_too_long)
  end

  test "import only offers boards the user can open" do
    login
    @secret.cards.create!(lane: :action_items, content: "Secret action")
    target = Board.create!(name: "Next sprint")

    get import_board_path(target)
    assert_select "select option", text: /Leads retro/, count: 0
    post import_action_items_board_path(target), params: { source_board_id: @secret.id, card_ids: @secret.cards.ids }
    assert_response :not_found
    assert_empty target.cards
  end

  test "the unlock page sends people straight to boards they can already open" do
    login
    get new_board_unlock_path(@open)
    assert_redirected_to board_path(@open)
  end

  private

  def login(name: "Sam")
    post session_path, params: { password: "retro", name: name }
  end
end
