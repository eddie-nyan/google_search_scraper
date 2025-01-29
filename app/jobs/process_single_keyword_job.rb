class ProcessSingleKeywordJob < ApplicationJob
  queue_as :google_search

  include Sidekiq::Throttled::Worker

  sidekiq_throttle(
    concurrency: { limit: 1 },
    threshold: { limit: 1, period: 60 }
  )

  def perform(keyword_id)
    keyword = Keyword.find(keyword_id)
    return if keyword.completed? || keyword.failed?

    GoogleSearchService.new(keyword).process
    Rails.logger.info "Successfully processed keyword: #{keyword.name}"
  rescue StandardError => e
    Rails.logger.error "Error processing keyword #{keyword.name}: #{e.message}"
    raise e
  end
end
