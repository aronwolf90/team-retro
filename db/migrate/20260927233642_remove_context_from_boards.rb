class RemoveContextFromBoards < ActiveRecord::Migration[8.1]
  def change
    remove_column :boards, :context, :text
  end
end
