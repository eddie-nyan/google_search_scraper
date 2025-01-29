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

  def process_keywords
    return unless file.attached?

    begin
      content = file.download
      keywords_count = 0

      # Start a transaction to ensure data consistency
      ActiveRecord::Base.transaction do
        # Parse CSV content
        CSV.parse(content) do |row|
          keyword_name = row[0]&.strip
          next if keyword_name.blank?

          # Create keyword record and associate it with the keyword file
          keyword = keywords.create!(
            name: keyword_name,
            status: "pending",
            processed_at: nil,
            search_volume: nil,
            adwords_advertisers_count: nil,
            total_links_count: nil,
            html_content: nil,
            search_metadata: {}
          )

          Rails.logger.info "Created keyword: #{keyword.name}"
          keywords_count += 1
        end

        # Update keyword file status and count
        update!(
          total_keywords: keywords_count,
          status: "processing"
        )

        Rails.logger.info "Successfully processed #{keywords_count} keywords"

        # Enqueue the background job to process keywords with Google search
        ProcessKeywordsJob.perform_later(self)
      end

    rescue StandardError => e
      Rails.logger.error "Error processing CSV: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      update(
        status: "failed"
      )
      raise e
    end
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
