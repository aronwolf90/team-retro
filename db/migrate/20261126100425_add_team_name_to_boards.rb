class AddTeamNameToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :team_name, :string
  end
end
