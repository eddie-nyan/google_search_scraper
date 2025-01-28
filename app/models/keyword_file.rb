class KeywordFile < ApplicationRecord
  belongs_to :user
  has_many :keywords, dependent: :destroy
  has_one_attached :file

  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
  validates :total_keywords, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_file, if: -> { file.attached? }

  scope :recent, -> { order(created_at: :desc) }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }

  before_validation :set_filename

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def self.process_csv(file_path)
    keywords = []
    CSV.foreach(file_path, headers: true) do |row|
      keywords << {
        name: row["keyword"],
        status: "pending"
      }
    end
    keywords
  end

  def update_status_and_total(status, total)
    update(
      status: status,
      total_keywords: total
    )
  end

  def validate_file
    unless file.content_type.in?(%w[text/csv application/csv])
      errors.add(:file, "must be a CSV file")
      return false
    end

    validate_file_size
  end

  private

  def set_filename
    if file.attached?
      self.filename = file.filename.to_s
    end
  end

  def validate_file_size
    if file.byte_size > 5.megabytes
      errors.add(:file, "size must be less than 5MB")
      false
    else
      true
    end
  end
end
