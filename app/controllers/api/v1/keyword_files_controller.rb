require "csv"

module Api
  module V1
    class KeywordFilesController < BaseController
      def create
        @keyword_file = current_user.keyword_files.build(keyword_file_params)
        @keyword_file.status = "pending"
        @keyword_file.total_keywords = 0

        if params.dig(:keyword_file, :file).present?
          uploaded_file = params.dig(:keyword_file, :file)
          keyword_count = count_keywords(uploaded_file)

          if keyword_count > 0 && keyword_count <= 100
            if @keyword_file.save
              @keyword_file.process_keywords
              render json: {
                status: { code: 200, message: "File uploaded successfully! Processing has begun." },
                data: {
                  keyword_file: {
                    id: @keyword_file.id,
                    filename: @keyword_file.filename,
                    status: @keyword_file.status,
                    total_keywords: keyword_count,
                    created_at: @keyword_file.created_at,
                    updated_at: @keyword_file.updated_at
                  }
                }
              }
            else
              Rails.logger.error "Save failed: #{@keyword_file.errors.full_messages}"
              render json: {
                status: {
                  code: 422,
                  message: "File upload failed",
                  errors: @keyword_file.errors.full_messages
                }
              }, status: :unprocessable_entity
            end
          else
            Rails.logger.error "Keyword count validation failed"
            render json: {
              status: {
                code: 422,
                message: "File must contain between 1 and 100 keywords. Current count: #{keyword_count}"
              }
            }, status: :unprocessable_entity
          end
        else
          Rails.logger.error "No file uploaded"
          render json: {
            status: {
              code: 422,
              message: "No file was uploaded"
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def keyword_file_params
        params.require(:keyword_file).permit(:file)
      end

      def count_keywords(uploaded_file)
        return 0 unless uploaded_file

        begin
          content = uploaded_file.read
          uploaded_file.rewind

          count = 0
          CSV.parse(content, headers: false) do |row|
            keyword = row[0]&.strip
            count += 1 if keyword.present?
          end
          count
        rescue StandardError => e
          Rails.logger.error "Error counting keywords: #{e.message}"
          0
        end
      end
    end
  end
end
