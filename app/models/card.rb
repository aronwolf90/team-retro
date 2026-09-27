class Card < ApplicationRecord
  belongs_to :board, touch: true
  belongs_to :parent, class_name: "Card", optional: true, counter_cache: false
  has_many :children, class_name: "Card", foreign_key: :parent_id, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :reactions, dependent: :destroy

  enum :lane, { went_well: 0, to_improve: 1, action_items: 2, how_is_everyone: 3, last_time: 4 }

  validates :content, presence: true, length: { maximum: 2000 }

  before_create :assign_position

  scope :roots, -> { where(parent_id: nil) }

  def merged?
    children.any?
  end

  def votes_count
    has_attribute?(:votes_count) ? self[:votes_count].to_i : votes.size
  end

  def votes_by(voter_token)
    votes.count { |v| v.voter_token == voter_token }
  end

  def reactions_by_emoji
    grouped = reactions.group_by(&:emoji)
    Reaction::EMOJIS.filter_map { |emoji| [ emoji, grouped[emoji] ] if grouped[emoji] }
  end

  def authored_by?(token)
    author_token.present? && author_token == token
  end

  def merge!(other)
    return if other == self || other.parent_id == id
    transaction do
      other.children.update_all(parent_id: id)
      other.votes.update_all(card_id: id)
      other.reactions.each do |reaction|
        if reactions.exists?(emoji: reaction.emoji, user_token: reaction.user_token)
          reaction.destroy
        else
          reaction.update!(card: self)
        end
      end
      other.update!(parent: self, lane: lane, position: 0)
    end
  end

  # Detach this merged card from its parent, making it a root card again.
  def unmerge!
    return unless parent
    transaction do
      update!(parent: nil, position: (board.root_cards.where(lane: lane).maximum(:position) || -1) + 1)
    end
  end

  # Move to +column_key+ and insert at +new_position+ (0-based) among that
  # column's root cards, then renumber the column so positions stay compact.
  def move_to!(column_key, new_position)
    transaction do
      siblings = board.root_cards.where(lane: column_key).where.not(id: id).order(:position, :created_at).to_a
      new_position = new_position.to_i.clamp(0, siblings.size)
      siblings.insert(new_position, self)
      self.lane = column_key
      siblings.each_with_index do |card, index|
        if card == self
          self.position = index
        elsif card.position != index
          card.update_columns(position: index)
        end
      end
      save!
    end
  end

  private

  def assign_position
    return if parent_id.present?
    self.position = (board.root_cards.where(lane: lane).maximum(:position) || -1) + 1
  end
end
