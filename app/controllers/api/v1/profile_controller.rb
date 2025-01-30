module Api
  module V1
    class ProfileController < BaseController
      def show
        render json: {
          status: { code: 200 },
          data: {
            user: {
              id: current_user.id,
              email: current_user.email
            }
          }
        }
      end
    end
  end
end
