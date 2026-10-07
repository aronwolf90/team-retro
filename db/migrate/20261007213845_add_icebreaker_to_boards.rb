class AddIcebreakerToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :icebreaker, :boolean, default: false, null: false
  end
end
