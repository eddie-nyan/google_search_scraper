module JwtHelper
  def generate_jwt_token(user)
    JWT.encode(
      {
        user_id: user.id,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base
    )
  end
end

RSpec.configure do |config|
  config.include JwtHelper, type: :request
end
