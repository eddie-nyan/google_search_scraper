require "csv"

class KeywordFilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_keyword_file, only: [ :show, :results ]

  def index
    @keyword_files = KeywordFile.recent
  end

  def show
    @keywords = @keyword_file.keywords.order(created_at: :desc)
  end

  def create
    @keyword_file = current_user.keyword_files.build(keyword_file_params)
    @keyword_file.status = "pending"
    @keyword_file.total_keywords = 0

    if params.dig(:keyword_file, :file).present?
      uploaded_file = params.dig(:keyword_file, :file)
      keyword_count = count_keywords(uploaded_file)

      if keyword_count > 0 && keyword_count <= 100
        # @keyword_file.total_keywords = keyword_count

        if @keyword_file.save
          # Process the keywords after successful save
          @keyword_file.process_keywords
          flash[:success] = "File uploaded successfully! Processing has begun."
          redirect_to keyword_files_path
        else
          Rails.logger.error "Save failed: #{@keyword_file.errors.full_messages}"
          flash[:error] = @keyword_file.errors.full_messages.join(", ")
          redirect_to keyword_files_path
        end
      else
        Rails.logger.error "Keyword count validation failed"
        flash[:error] = "File must contain between 1 and 100 keywords. Current count: #{keyword_count}"
        redirect_to keyword_files_path
      end
    else
      Rails.logger.error "No file uploaded"
      flash[:error] = "No file was uploaded"
      redirect_to keyword_files_path
    end
  end

  def results
    @keywords = @keyword_file.keywords.order(created_at: :desc)
  end

  private

  def set_keyword_file
    @keyword_file = current_user.keyword_files.find(params[:id])
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

  def keyword_file_params
    params.require(:keyword_file).permit(:file)
  end
end
