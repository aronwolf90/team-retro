class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :card, null: false, foreign_key: true
      t.string :voter_token, null: false

      t.timestamps
    end
    add_index :votes, [ :card_id, :voter_token ]
  end
end
