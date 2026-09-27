# Example board so the app is not empty on first start.
board = Board.find_or_create_by!(name: "Example sprint retro") do |b|
  b.context = "A sample board. Drag cards between columns, drop one card on another to merge them, vote with 👍."
  b.max_votes = 6
end

if board.cards.none?
  board.cards.create!(lane: :how_is_everyone, content: "Tired but happy, the release is out 😅", author_name: "Alex")
  went_well = board.cards.create!(lane: :went_well, content: "Pair programming on the payment bug worked great", author_name: "Alex")
  board.cards.create!(lane: :went_well, content: "Release went out on time 🎉", author_name: "Sam")
  board.cards.create!(lane: :to_improve, content: "Too many meetings on Tuesday", author_name: "Alex")
  board.cards.create!(lane: :to_improve, content: "CI pipeline is flaky", author_name: "Kim")
  board.cards.create!(lane: :action_items, content: "Kim: investigate flaky specs by Friday", author_name: "Sam")
  went_well.votes.create!([ { voter_token: "seed-1" }, { voter_token: "seed-2" } ])
  went_well.comments.create!(body: "Let's keep this up next sprint!", author_name: "Kim")
end
