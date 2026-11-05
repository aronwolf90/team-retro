class AddColumnTitlesToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :column_titles, :text, default: "{}", null: false
  end
end
