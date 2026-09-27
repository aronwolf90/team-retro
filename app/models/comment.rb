class Comment < ApplicationRecord
  belongs_to :card, touch: true
  validates :body, presence: true, length: { maximum: 2000 }
end
