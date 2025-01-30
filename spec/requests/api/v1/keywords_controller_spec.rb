require "rails_helper"

RSpec.describe Api::V1::KeywordsController, type: :request do
  let(:user) { create(:user) }
  let(:token) { generate_jwt_token(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:keyword_file) { create(:keyword_file, user: user) }
  let!(:keywords) { create_list(:keyword, 3, keyword_file: keyword_file) }

  describe "GET /api/v1/keyword_files/:keyword_file_id/keywords" do
    context "when user is not authenticated" do
      it "returns unauthorized status" do
        get "/api/v1/keyword_files/#{keyword_file.id}/keywords"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      it "returns list of keywords" do
        get "/api/v1/keyword_files/#{keyword_file.id}/keywords", headers: headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["status"]["code"]).to eq(200)
        expect(json["data"]["keywords"].length).to eq(3)
        expect(json["data"]["keyword_file"]["id"]).to eq(keyword_file.id)
      end

      context "when keyword file doesn't exist" do
        it "returns not found status" do
          get "/api/v1/keyword_files/0/keywords", headers: headers

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)

          expect(json["status"]["code"]).to eq(404)
          expect(json["status"]["message"]).to eq("Keyword file not found")
        end
      end
    end
  end
end
