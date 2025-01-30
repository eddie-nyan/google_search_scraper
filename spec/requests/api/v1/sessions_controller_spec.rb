require "rails_helper"

RSpec.describe Api::V1::SessionsController, type: :request do
  describe "POST /api/v1/sign_in" do
    let(:user) { create(:user) }
    let(:valid_params) do
      {
        user: {
          email: user.email,
          password: "password123"
        }
      }
    end

    context "with valid credentials" do
      it "returns JWT token and user info" do
        post "/api/v1/sign_in", params: valid_params

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["status"]["code"]).to eq(200)
        expect(json["status"]["message"]).to eq("Signed in successfully.")
        expect(json["data"]["user"]["email"]).to eq(user.email)
        expect(json["data"]["token"]).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized status" do
        post "/api/v1/sign_in", params: { user: { email: user.email, password: "wrong" } }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)

        expect(json["status"]["code"]).to eq(401)
        expect(json["status"]["message"]).to eq("Invalid email or password.")
      end
    end
  end
end
