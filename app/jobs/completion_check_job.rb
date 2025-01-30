class CompletionCheckJob < ApplicationJob
  queue_as :default

  def perform(keyword_file_id)
    keyword_file = KeywordFile.find(keyword_file_id)
    total_keywords = keyword_file.keywords.count
    completed_keywords = keyword_file.keywords.where(status: "completed").count
    failed_keywords = keyword_file.keywords.where(status: "failed").count
    pending_keywords = keyword_file.keywords.where(status: "pending").count

    # Check if any jobs are still in Sidekiq queue or processing
    jobs_in_queue = count_jobs_in_queue(keyword_file.keywords.pluck(:id))

    if pending_keywords.zero? && jobs_in_queue.zero?
      # All jobs completed and no pending jobs in Sidekiq
      if failed_keywords == total_keywords
        keyword_file.update!(status: "failed")
      else
        keyword_file.update!(status: "completed")
      end

      Rails.logger.info "Keyword file #{keyword_file.id} processing completed. " \
                       "Total: #{total_keywords}, " \
                       "Completed: #{completed_keywords}, " \
                       "Failed: #{failed_keywords}"
    else
      # Check again in 30 seconds if jobs are still pending
      CompletionCheckJob.set(wait: 30.seconds).perform_later(keyword_file_id)
    end
  end

  private

  def count_jobs_in_queue(keyword_ids)
    # Check scheduled set
    scheduled = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == "ProcessSingleKeywordJob" &&
      keyword_ids.include?(job.args.first)
    end.count

    # Check retry set
    retrying = Sidekiq::RetrySet.new.select do |job|
      job.klass == "ProcessSingleKeywordJob" &&
      keyword_ids.include?(job.args.first)
    end.count

    # Check processing set
    processing = Sidekiq::Workers.new.select do |_, _, work|
      work["payload"]["class"] == "ProcessSingleKeywordJob" &&
      keyword_ids.include?(work["payload"]["args"].first)
    end.count

    # Check queue
    queued = Sidekiq::Queue.new("google_search").select do |job|
      job.klass == "ProcessSingleKeywordJob" &&
      keyword_ids.include?(job.args.first)
    end.count

    scheduled + retrying + processing + queued
  end
end
