class SearchResult < ApplicationRecord
  belongs_to :keyword

  validates :total_adwords, numericality: { greater_than_or_equal_to: 0 }
  validates :total_links, numericality: { greater_than_or_equal_to: 0 }
  validates :total_results, presence: true
  validates :html_cache, presence: true
end
