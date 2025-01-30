class ProcessSingleKeywordJob < ApplicationJob
  queue_as :google_search

  include Sidekiq::Throttled::Worker

  sidekiq_throttle(
    concurrency: { limit: 1 },
    threshold: { limit: 1, period: 60 }
  )

  sidekiq_options retry: 5,
                 backtrace: true,
                 retry_in: ->(count) {
                   # Exponential backoff: 1min, 5min, 15min, 30min, 60min
                   [ 1, 5, 15, 30, 60 ][count - 1].minutes
                 }

  def perform(keyword_id)
    keyword = Keyword.find(keyword_id)
    return if keyword.completed? || keyword.failed?

    begin
      GoogleSearchService.new(keyword).process
      Rails.logger.info "Successfully processed keyword: #{keyword.name}"
    rescue StandardError => e
      Rails.logger.warn "Error processing keyword, will retry: #{e.message}"
      raise e # Re-raise to trigger Sidekiq retry with backoff
    end
  end
end
