FactoryBot.define do
  factory :keyword do
    keyword_file
    sequence(:name) { |n| "keyword#{n}" }
    status { "pending" }
    search_volume { 1000 }
    adwords_advertisers_count { 5 }
    total_links_count { 100 }
    search_metadata { { "search_time" => 0.5 } }
    processed_at { Time.current }
  end
end
