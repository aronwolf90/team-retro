class Board < ApplicationRecord
  # The default EasyRetro-style kanban board: the three columns are fixed.
  COLUMNS = [
    { key: :how_is_everyone, title: "How is everyone?", color: "blue" },
    { key: :last_time, title: "From last retro", color: "orange" },
    { key: :went_well,    title: "Went Well",    color: "green"  },
    { key: :to_improve,   title: "To Improve",   color: "red"    },
    { key: :action_items, title: "Action Items", color: "purple" }
  ].freeze

  SORT_OPTIONS = %w[order votes].freeze
  LANE_KEYS = COLUMNS.map { |c| c[:key].to_s }.freeze

  # Columns whose cards are hidden from everyone except their author.
  serialize :hidden_lanes, coder: JSON

  has_many :cards, dependent: :destroy
  has_many :votes, through: :cards
  has_many :reactions, through: :cards

  validates :name, presence: true, length: { maximum: 120 }
  validates :max_votes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99 }
  validates :sort_by, inclusion: { in: SORT_OPTIONS }

  broadcasts_refreshes

  def previous
    Board.where.not(id: id).where(created_at: ...created_at).order(created_at: :desc).first
  end

  def import_action_items_from(source)
    return 0 unless source
    imported = 0
    source.cards_in(:action_items).each do |card|
      lines = [ card.content, *card.children.map(&:content) ]
      cards.create!(lane: :last_time, content: lines.join("\n\n"), author_name: card.author_name)
      imported += 1
    end
    imported
  end

  def hidden_lanes=(value)
    super(Array(value).map(&:to_s).select { |lane| LANE_KEYS.include?(lane) }.uniq)
  end

  def lane_hidden?(lane)
    hidden_lanes.include?(lane.to_s)
  end

  def toggle_lane_hidden!(lane)
    lane = lane.to_s
    update!(hidden_lanes: lane_hidden?(lane) ? hidden_lanes - [ lane ] : hidden_lanes + [ lane ])
  end

  def any_lane_hidden?
    hidden_lanes.any?
  end

  # Top-level cards (merged cards live under their parent).
  def root_cards
    cards.where(parent_id: nil)
  end

  def cards_in(column_key)
    scope = root_cards.where(lane: column_key)
      .select("cards.*, (SELECT COUNT(*) FROM votes WHERE votes.card_id = cards.id) AS votes_count")
      .includes(:votes, :reactions, children: [ :votes, :reactions ])
    if sort_by == "votes"
      scope.order(Arel.sql("votes_count DESC"), :position, :created_at)
    else
      scope.order(:position, :created_at)
    end
  end

  def votes_used_by(voter_token)
    votes.where(voter_token: voter_token).count
  end

  def votes_left_for(voter_token)
    [ max_votes - votes_used_by(voter_token), 0 ].max
  end

  def timer_running?
    timer_ends_at.present? && timer_ends_at > Time.current
  end

  def timer_finished?
    timer_ends_at.present? && timer_ends_at <= Time.current
  end
end
