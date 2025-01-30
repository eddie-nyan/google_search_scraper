class Keyword < ApplicationRecord
  belongs_to :keyword_file
  has_one :user, through: :keyword_file
  # has_one :search_result, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :search_volume, presence: true, allow_nil: true
  validates :adwords_advertisers_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :total_links_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }

  # Scopes
  scope :processed, -> { where.not(processed_at: nil) }
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Status helpers
  def processed?
    processed_at.present?
  end

  def processing_failed?
    status == "failed"
  end

  def processing_time
    processed_at - created_at if processed?
  end

  def position_in_file
    # Get position based on creation order within the file
    keyword_file.keywords.where("created_at <= ?", created_at).count - 1
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def search_time
    search_metadata&.dig("search_time")
  end

  # enum status: {
  #   pending: 0,
  #   processing: 1,
  #   completed: 2,
  #   failed: 3
  # }
end
