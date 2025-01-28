class ProcessKeywordsJob < ApplicationJob
  queue_as :default

  def perform(keyword_file)
    return unless keyword_file.file.attached?

    begin
      require "csv"
      blob = keyword_file.file.blob
      content = blob.download.force_encoding("UTF-8")
      csv = CSV.parse(content, headers: true)
      keywords = csv.map { |row| row["keyword"] }.compact.map(&:strip).reject(&:empty?)

      if keywords.size > 100
        keyword_file.update(status: "failed")
        return
      end

      ActiveRecord::Base.transaction do
        keyword_file.update!(
          total_keywords: keywords.size,
          status: "processing"
        )

        keywords.each do |term|
          keyword_file.keywords.create!(
            name: term,
            status: "pending"
          )
        end

        keyword_file.update!(status: "completed")
      end
    rescue StandardError => e
      Rails.logger.error "Error processing keywords: #{e.message}"
      keyword_file.update(status: "failed")
    end
  end
end
