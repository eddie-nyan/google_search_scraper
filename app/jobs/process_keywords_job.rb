class ProcessKeywordsJob < ApplicationJob
  queue_as :google_search

  include Sidekiq::Throttled::Worker

  # Configure throttling and retries
  sidekiq_throttle(
    concurrency: { limit: 1 },             # Only one concurrent job
    threshold: { limit: 1, period: 60 }    # One job per minute
  )

  # Increase retries and add exponential backoff for captcha issues
  sidekiq_options retry: 5,
                 backtrace: true,
                 retry_in: ->(count) {
                   # Exponential backoff: 1min, 5min, 15min, 30min, 60min
                   [ 1, 5, 15, 30, 60 ][count - 1].minutes
                 }

  def perform(keyword_file)
    pending_keywords = keyword_file.keywords.where(status: "pending")
    last_job_delay = 0

    # Schedule each keyword as a separate job
    pending_keywords.each_with_index do |keyword, index|
      delay = calculate_delay(index)
      last_job_delay = delay if index == pending_keywords.size - 1
      ProcessSingleKeywordJob.set(wait: delay).perform_later(keyword.id)
    end

    # Schedule completion check after estimated completion of last job
    CompletionCheckJob.set(wait: last_job_delay + 1.minute).perform_later(keyword_file.id)
  rescue StandardError => e
    keyword_file.update(status: "failed")
    raise e
  end

  private

  def calculate_delay(index)
    base_delay = 3.minutes
    jitter = rand(-30..30).seconds
    (index * base_delay) + jitter
  end
end
