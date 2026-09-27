class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :board, null: false, foreign_key: true
      t.integer :lane, null: false, default: 0
      t.text :content, null: false
      t.string :author_name
      t.string :author_token
      t.integer :position, null: false, default: 0
      t.references :parent, foreign_key: { to_table: :cards }

      t.timestamps
    end
    add_index :cards, [ :board_id, :lane, :position ]
  end
end
