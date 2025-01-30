require "rails_helper"

RSpec.describe Api::V1::KeywordFilesController, type: :request do
  let(:user) { create(:user) }
  let(:token) { generate_jwt_token(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/v1/keyword_files" do
    let(:file) { fixture_file_upload("spec/fixtures/files/valid_keywords.csv", "text/csv") }
    let(:valid_params) { { keyword_file: { file: file } } }

    context "when user is not authenticated" do
      it "returns unauthorized status" do
        post "/api/v1/keyword_files", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "with valid file" do
        it "creates a new keyword file and starts processing" do
          expect {
            post "/api/v1/keyword_files", params: valid_params, headers: headers
          }.to change(KeywordFile, :count).by(1)

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)

          expect(json["status"]["code"]).to eq(200)
          expect(json["status"]["message"]).to include("Processing has begun")
          expect(json["data"]["keyword_file"]).to include(
            "filename" => "valid_keywords.csv",
            "status" => "pending"
          )
        end
      end

      context "with invalid file" do
        let(:empty_file) { fixture_file_upload("spec/fixtures/files/empty.csv", "text/csv") }

        it "returns error for empty file" do
          post "/api/v1/keyword_files",
            params: { keyword_file: { file: empty_file } },
            headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json["status"]["code"]).to eq(422)
          expect(json["status"]["message"]).to include("must contain between 1 and 100 keywords")
        end
      end

      context "with no file" do
        it "returns error" do
          post "/api/v1/keyword_files",
            params: { keyword_file: { file: nil } },
            headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json["status"]["code"]).to eq(422)
          expect(json["status"]["message"]).to eq("No file was uploaded")
        end
      end
    end
  end
end
