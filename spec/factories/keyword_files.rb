FactoryBot.define do
  factory :keyword_file do
    user
    status { "pending" }
    total_keywords { 3 }

    after(:build) do |keyword_file|
      keyword_file.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/valid_keywords.csv")),
        filename: "valid_keywords.csv",
        content_type: "text/csv"
      )
    end
  end
end
