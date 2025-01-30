module Api
  module V1
    class KeywordsController < BaseController
      def index
        keyword_file = current_user.keyword_files.find(params[:keyword_file_id])
        keywords = keyword_file.keywords.order(created_at: :asc)

        render json: {
          status: { code: 200 },
          data: {
            keyword_file: {
              id: keyword_file.id,
              filename: keyword_file.filename,
              status: keyword_file.status,
              total_keywords: keyword_file.total_keywords,
              created_at: keyword_file.created_at,
              updated_at: keyword_file.updated_at
            },
            keywords: keywords.map { |keyword|
              {
                id: keyword.id,
                name: keyword.name,
                status: keyword.status,
                search_volume: keyword.search_volume,
                advertisers_count: keyword.adwords_advertisers_count,
                total_links: keyword.total_links_count,
                search_time: keyword.search_metadata&.dig("search_time"),
                processed_at: keyword.processed_at&.iso8601
              }
            }
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: "Keyword file not found" }
        }, status: :not_found
      end
    end
  end
end
