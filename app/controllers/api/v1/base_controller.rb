module Api
  module V1
    class BaseController < ApplicationController
      include JwtAuthenticatable
      skip_before_action :verify_authenticity_token
      respond_to :json
    end
  end
end
