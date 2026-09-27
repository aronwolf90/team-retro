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

  test "merge! moves votes and comments to the parent and unmerge! splits again" do
    @b.votes.create!(voter_token: "v1")
    @b.comments.create!(body: "hi", author_name: "x")
    @a.merge!(@b)

    @a.reload
    assert_equal [ @b ], @a.children.to_a
    assert_equal 1, @a.votes.count
    assert_equal 1, @a.comments.count
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
end
