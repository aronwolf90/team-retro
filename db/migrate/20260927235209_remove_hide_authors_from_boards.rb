class RemoveHideAuthorsFromBoards < ActiveRecord::Migration[8.1]
  def up
    remove_column :boards, :hide_authors
    execute "UPDATE boards SET sort_by = 'order' WHERE sort_by = 'created'"
  end

  def down
    add_column :boards, :hide_authors, :boolean, null: false, default: false
  end
end
