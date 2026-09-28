require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @board = Board.create!(name: "Retro", max_votes: 3)
    @a = @board.cards.create!(lane: :went_well, content: "A", author_token: "t1")
    @b = @board.cards.create!(lane: :went_well, content: "B", author_token: "t2")
    @c = @board.cards.create!(lane: :to_improve, content: "C", author_token: "t1")
  end

  test "new cards get incrementing positions per lane" do
    assert_equal [ 0, 1 ], [ @a.position, @b.position ]
    assert_equal 0, @c.position
  end

  test "move_to! reorders within a lane and moves between lanes" do
    @c.move_to!("went_well", 0)
    assert_equal %w[C A B], @board.cards_in(:went_well).map(&:content)
    assert_equal [ 0, 1, 2 ], @board.cards_in(:went_well).map(&:position)

    @a.move_to!("action_items", 99)
    assert_equal %w[A], @board.cards_in(:action_items).map(&:content)
    assert_equal %w[C B], @board.cards_in(:went_well).map(&:content)
  end

  test "merge! moves votes and reactions to the parent and unmerge! splits again" do
    @b.votes.create!(voter_token: "v1")
    @b.reactions.create!(emoji: "🎉", user_token: "t1")
    @b.reactions.create!(emoji: "🔥", user_token: "t2")
    @a.reactions.create!(emoji: "🎉", user_token: "t1")
    @a.merge!(@b)

    @a.reload
    assert_equal [ @b ], @a.children.to_a
    assert_equal 1, @a.votes.count
    assert_equal [ [ "🎉", 1 ], [ "🔥", 1 ] ], @a.reactions_by_emoji.map { |emoji, list| [ emoji, list.size ] }
    assert_equal %w[A], @board.cards_in(:went_well).map(&:content)

    @b.reload.unmerge!
    assert_nil @b.reload.parent_id
    assert_equal %w[A B], @board.cards_in(:went_well).map(&:content)
  end

  test "merging into a merged card flattens grandchildren" do
    @a.merge!(@b)
    @c.merge!(@a)
    assert_equal [ @a, @b ].map(&:id).sort, @c.reload.children.pluck(:id).sort
  end

  test "board sorts by votes" do
    @board.update!(sort_by: "votes")
    2.times { @b.votes.create!(voter_token: "v1") }
    assert_equal %w[B A], @board.cards_in(:went_well).map(&:content)
    assert_equal [ 2, 0 ], @board.cards_in(:went_well).map(&:votes_count)
  end

  test "votes_left_for respects max votes" do
    3.times { @a.votes.create!(voter_token: "v1") }
    assert_equal 0, @board.votes_left_for("v1")
    assert_equal 3, @board.votes_left_for("v2")
  end

  test "a new board imports the previous board's action items, merged cards flattened" do
    todo = @board.cards.create!(lane: :action_items, content: "Fix CI", author_name: "Kim")
    todo.merge!(@board.cards.create!(lane: :action_items, content: "Also flaky specs"))
    @board.cards.create!(lane: :action_items, content: "Write docs")

    next_board = Board.create!(name: "Next")
    assert_equal @board, next_board.previous
    assert_equal 2, next_board.import_action_items_from(next_board.previous)
    assert_equal [ "Fix CI\n\nAlso flaky specs", "Write docs" ], next_board.cards_in(:last_time).map(&:content)
    assert_equal "Kim", next_board.cards_in(:last_time).first.author_name
    assert_equal 0, Board.create!(name: "Lonely").import_action_items_from(nil)
  end

  test "hidden lanes tolerate a missing value" do
    @board.update_column(:hidden_lanes, nil)
    assert_equal [], @board.reload.hidden_lanes
    assert_not @board.lane_hidden?(:went_well)
    @board.toggle_lane_hidden!(:went_well)
    assert @board.reload.lane_hidden?(:went_well)
  end
end
