class ReplaceCommentsWithReactions < ActiveRecord::Migration[8.1]
  def up
    create_table :reactions do |t|
      t.references :card, null: false, foreign_key: true
      t.string :emoji, null: false
      t.string :user_name
      t.string :user_token, null: false

      t.timestamps
    end
    add_index :reactions, [ :card_id, :emoji, :user_token ], unique: true

    drop_table :comments
  end

  def down
    create_table :comments do |t|
      t.references :card, null: false, foreign_key: true
      t.text :body, null: false
      t.string :author_name
      t.string :author_token

      t.timestamps
    end

    drop_table :reactions
  end
end
