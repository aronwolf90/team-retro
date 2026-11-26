module ApplicationHelper
  def board_option_label(board)
    "#{board.name}#{" · #{board.team_name}" if board.team_name} (#{board.created_at.strftime('%b %-d, %Y')})"
  end
end
