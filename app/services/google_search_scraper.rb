require "nokogiri"
require "open-uri"
require "net/http"

class GoogleSearchScraper
  USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    # Add more user agents for rotation
  ]

  def initialize(keyword)
    @keyword = keyword
  end

  def scrape
    html = fetch_search_results
    parse_results(html)
  end

  private

  def fetch_search_results
    uri = URI("https://www.google.com/search?q=#{URI.encode_www_form_component(@keyword.term)}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENTS.sample
    request["Accept"] = "text/html"
    request["Accept-Language"] = "en-US,en;q=0.9"

    response = http.request(request)
    response.body
  end

  def parse_results(html)
    doc = Nokogiri::HTML(html)

    {
      total_adwords: count_adwords(doc),
      total_links: count_links(doc),
      total_results: extract_total_results(doc),
      html_cache: html
    }
  end

  def count_adwords(doc)
    doc.css('div[data-text-ad="1"]').count
  end

  def count_links(doc)
    doc.css("a").count
  end

  def extract_total_results(doc)
    doc.css("#result-stats").text.strip
  end
end
