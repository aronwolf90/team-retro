class Reaction < ApplicationRecord
  EMOJIS = %w[❤️ 🎉 😂 😮 😢 🔥 👀 💯 🙏 🤔].freeze

  belongs_to :card, touch: true

  validates :emoji, inclusion: { in: EMOJIS }
  validates :user_token, presence: true, uniqueness: { scope: [ :card_id, :emoji ] }
end
