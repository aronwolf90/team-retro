class Vote < ApplicationRecord
  belongs_to :card, touch: true
  validates :voter_token, presence: true
end
