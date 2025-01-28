class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @keyword_file = KeywordFile.new
    @keyword_files = current_user.keyword_files.order(created_at: :desc)
  end
end
