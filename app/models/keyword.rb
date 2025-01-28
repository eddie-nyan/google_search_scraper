class Keyword < ApplicationRecord
  belongs_to :keyword_file
  has_one :search_result, dependent: :destroy

  validates :term, presence: true

  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }
end
