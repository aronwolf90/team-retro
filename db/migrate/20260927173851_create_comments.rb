class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :card, null: false, foreign_key: true
      t.text :body, null: false
      t.string :author_name
      t.string :author_token

      t.timestamps
    end
  end
end
