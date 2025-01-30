require "jwt"

module Api
  module V1
    class SessionsController < Devise::SessionsController
      skip_before_action :verify_authenticity_token
      respond_to :json

      def create
        user = User.find_by(email: sign_in_params[:email])

        if user&.valid_password?(sign_in_params[:password])
          @current_user = user
          render json: {
            status: { code: 200, message: "Signed in successfully." },
            data: {
              user: {
                id: user.id,
                email: user.email
              },
              token: generate_jwt_token(user)
            }
          }
        else
          render json: {
            status: { code: 401, message: "Invalid email or password." }
          }, status: :unauthorized
        end
      end

      private

      def sign_in_params
        params.require(:user).permit(:email, :password)
      end

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
  end
end
