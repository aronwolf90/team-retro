class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.string :name, null: false
      t.text :context
      t.integer :max_votes, null: false, default: 6
      t.boolean :hide_cards, null: false, default: false
      t.boolean :hide_votes, null: false, default: false
      t.boolean :hide_authors, null: false, default: false
      t.string :sort_by, null: false, default: "order"
      t.datetime :timer_ends_at

      t.timestamps
    end
  end
end
