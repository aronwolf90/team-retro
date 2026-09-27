class ReplaceHideCardsWithHiddenLanes < ActiveRecord::Migration[8.1]
  def up
    add_column :boards, :hidden_lanes, :text, null: false, default: "[]"
    execute <<~SQL
      UPDATE boards SET hidden_lanes = '["went_well","to_improve","action_items"]' WHERE hide_cards = 1
    SQL
    remove_column :boards, :hide_cards
  end

  def down
    add_column :boards, :hide_cards, :boolean, null: false, default: false
    execute "UPDATE boards SET hide_cards = 1 WHERE hidden_lanes <> '[]'"
    remove_column :boards, :hidden_lanes
  end
end
