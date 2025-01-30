require "jwt"

module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_jwt!
  end

  private

  def authenticate_jwt!
    return render_unauthorized unless auth_token.present?

    begin
      @decoded = JWT.decode(auth_token, Rails.application.credentials.secret_key_base).first
      @current_user = User.find(@decoded["user_id"])
    rescue JWT::ExpiredSignature
      render_unauthorized("Auth token has expired")
    rescue JWT::DecodeError
      render_unauthorized("Invalid auth token")
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("User not found")
    end
  end

  def auth_token
    @auth_token ||= request.headers["Authorization"]&.split(" ")&.last
  end

  def render_unauthorized(message = "Unauthorized")
    render json: {
      status: { code: 401, message: message }
    }, status: :unauthorized
  end
end
