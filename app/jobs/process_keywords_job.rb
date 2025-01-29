class ProcessKeywordsJob < ApplicationJob
  queue_as :google_search

  include Sidekiq::Throttled::Worker

  # Configure throttling directly
  sidekiq_throttle(
    concurrency: { limit: 1 },             # Only one concurrent job
    threshold: { limit: 1, period: 60 }    # One job per minute
  )

  BATCH_SIZE = 3  # Reduced batch size
  BATCH_DELAY = 180..360  # 3-6 minutes between batches
  KEYWORD_DELAY = 120..240  # 2-4 minutes between keywords
  ERROR_DELAY = 300..600  # 5-10 minutes after error

  def perform(keyword_file)
    # Get all pending keywords
    pending_keywords = keyword_file.keywords.where(status: "pending")

    # Process each keyword as a separate job
    pending_keywords.each do |keyword|
      # Schedule each keyword with increasing delay
      ProcessSingleKeywordJob.set(wait: calculate_delay(keyword)).perform_later(keyword.id)
    end

    # Update file status when all keywords are processed
    check_completion(keyword_file)
  rescue StandardError => e
    keyword_file.update(status: "failed")
    raise e
  end

  private

  def calculate_delay(keyword)
    # Calculate delay based on keyword position
    position = keyword.position_in_file || 0
    base_delay = 3.minutes
    jitter = rand(-30..30)  # Random jitter between -30 and +30 seconds

    (position * base_delay) + jitter.seconds
  end

  def check_completion(keyword_file)
    # keyword_file = KeywordFile.find(keyword_file_id)
    pending_count = keyword_file.keywords.where(status: "pending").count

    if pending_count.zero?
      keyword_file.update(status: "completed")
    else
      # CompletionCheckJob.set(wait: 1.hour).perform_later(keyword_file.id)
    end
  end
end
