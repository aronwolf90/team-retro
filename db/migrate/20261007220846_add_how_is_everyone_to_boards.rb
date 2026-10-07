class AddHowIsEveryoneToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :how_is_everyone, :boolean, default: true, null: false
  end
end
