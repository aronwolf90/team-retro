require "test_helper"

class TeamGroupingTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { password: "retro", name: "Sam" }
  end

  test "team names are trimmed and reuse the spelling of an existing team" do
    Board.create!(name: "Retro 1", team_name: "Payments")
    assert_equal "Payments", Board.create!(name: "Retro 2", team_name: "  payments ").team_name
    assert_nil Board.create!(name: "Retro 3", team_name: "  ").team_name
    assert_equal %w[Payments], Board.team_names
  end

  test "the dashboard groups boards by team and filters by the chosen team" do
    Board.create!(name: "Payments retro", team_name: "Payments")
    Board.create!(name: "Platform retro", team_name: "Platform")
    Board.create!(name: "Old retro")

    get boards_path
    assert_select ".chip", count: 3
    assert_select ".chip--active", text: "All teams"
    assert_select ".board-group__title", count: 3
    assert_select ".board-group__title", text: "No team"

    get boards_path(team: "Platform")
    assert_select ".chip--active", text: "Platform"
    assert_select ".board-item__name", count: 1, text: "Platform retro"

    # the choice is remembered and preselects the team for new boards
    get boards_path
    assert_select ".board-item__name", count: 1, text: "Platform retro"
    get new_board_path
    assert_select "input[name='board[team_name]'][value=Platform]"
    assert_select "datalist#team-names option", count: 2

    get boards_path(team: "")
    assert_select ".board-item", count: 3
  end

  test "the dashboard has no team headings while no board has a team" do
    Board.create!(name: "Old retro")
    get boards_path
    assert_select ".team-filter", count: 0
    assert_select ".board-group__title", count: 0
    assert_select ".board-item", count: 1
  end

  test "creating a board with a team selects that team on the dashboard" do
    post boards_path, params: { board: { name: "Sprint 1", team_name: "Payments" } }
    assert_equal "Payments", Board.last.team_name
    get boards_path
    assert_select ".chip--active", text: "Payments"
  end

  test "importing defaults to the newest earlier board of the same team" do
    own = Board.create!(name: "Payments sprint 1", team_name: "Payments", created_at: 2.days.ago)
    Board.create!(name: "Platform sprint 1", team_name: "Platform", created_at: 1.day.ago)
    board = Board.create!(name: "Payments sprint 2", team_name: "Payments")

    get import_board_path(board)
    assert_select "select option[selected][value=?]", own.id.to_s, text: /Payments sprint 1 · Payments/
  end
end
