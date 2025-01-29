require "nokogiri"
require "selenium-webdriver"
require "proxy_fetcher"
require "httparty"

class GoogleSearchService
  USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
  ]

  INTERMEDIATE_SITES = [
    "https://www.wikipedia.org/wiki/Special:Random",
    "https://news.ycombinator.com",
    "https://www.reddit.com/r/random",
    "https://medium.com/",
    "https://dev.to"
  ]

  MAX_RETRIES = 3
  PROXY_ROTATION_COUNT = 5

  def initialize(keyword)
    @keyword = keyword
    @user_agent = USER_AGENTS.sample
    @retry_count = 0
    @use_proxies = false  # Set to true to enable proxy usage
    @proxies = @use_proxies ? fetch_proxies : []
  end

  def process
    begin
      search_results = fetch_search_results

      organic_links = search_results.css("div.g a").map do |link|
        href = link["href"]
        extract_actual_url(href) if href.start_with?("/url?") # Filter non-result links
      rescue
        nil
      end.compact
      Rails.logger.info "Organic links: #{organic_links}"

      @keyword.update!(
        search_volume: extract_search_volume(search_results),
        adwords_advertisers_count: count_adwords_advertisers(search_results),
        total_links_count: count_total_links(search_results),
        html_content: search_results.to_html,
        status: "completed",
        processed_at: Time.current,
        search_metadata: {
          processed_at: Time.current,
          search_time: extract_search_time(search_results)
        }
      )
    rescue StandardError => e
      @keyword.update!(
        status: "failed",
        error_message: e.message
      )
      raise e
    end
  end

  private

  def fetch_search_results
    while @retry_count < MAX_RETRIES
      proxy = @use_proxies ? @proxies.sample : nil
      options = configure_chrome_options(proxy)

      driver = Selenium::WebDriver.for :chrome, options: options

      begin
        result = perform_search(driver)
        return result if result
      rescue StandardError => e
        handle_search_error(e)
      ensure
        driver.quit
      end

      @retry_count += 1
      rotate_proxy if @use_proxies && @retry_count % PROXY_ROTATION_COUNT == 0
    end

    raise "Max retries reached for keyword: #{@keyword.name}"
  end

  def configure_chrome_options(proxy)
    options = Selenium::WebDriver::Chrome::Options.new

    # Basic Chrome settings
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--start-maximized")

    # Enhanced anti-detection settings
    options.add_argument("--user-agent=#{@user_agent}")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--lang=en-US,en;q=0.9")
    options.add_argument("--accept-lang=en-US,en;q=0.9")
    options.add_argument("--disable-infobars")
    options.add_argument("--disable-extensions")
    options.add_argument("--incognito")

    # Additional stealth settings
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-software-rasterizer")
    options.add_argument("--disable-dev-tools")
    options.add_argument("--no-first-run")
    options.add_argument("--no-default-browser-check")
    options.add_argument("--disable-background-networking")
    options.add_argument("--disable-sync")
    options.add_argument("--disable-translate")
    options.add_argument("--hide-scrollbars")
    options.add_argument("--metrics-recording-only")
    options.add_argument("--mute-audio")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-web-security")

    # Add WebGL and Canvas fingerprint randomization
    options.add_argument("--disable-webgl")
    options.add_argument("--disable-canvas-aa")
    options.add_argument("--disable-2d-canvas-clip-aa")
    options.add_argument("--disable-gl-drawing-for-tests")

    # Additional preferences for stealth
    options.add_preference("profile.default_content_setting_values.notifications", 2)
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("profile.default_content_settings.popups", 0)
    options.add_preference("profile.managed_default_content_settings.images", 1)
    options.add_preference("profile.default_content_setting_values.cookies", 1)
    options.add_preference("profile.cookie_controls_mode", 0)
    options.add_preference("profile.block_third_party_cookies", false)
    options.add_preference("profile.default_content_setting_values.plugins", 1)
    options.add_preference("profile.content_settings.exceptions.plugins.*,*.per_resource.adobe-flash-player", 1)
    options.add_preference("profile.content_settings.exceptions.plugins.*,*.per_resource.flash", 1)

    # Add proxy if available
    if proxy
      begin
        proxy_server = "#{proxy.addr}:#{proxy.port}"
        options.add_argument("--proxy-server=#{proxy_server}")
        Rails.logger.info "Using proxy: #{proxy_server}"
      rescue StandardError => e
        Rails.logger.error "Error setting proxy: #{e.message}"
      end
    end

    options
  end

  def perform_search(driver)
    # Execute stealth script before any action
    inject_stealth_scripts(driver)

    # More random initial delay
    sleep(rand(5..15))

    # Visit Google homepage and wait
    driver.navigate.to "https://www.google.com"
    sleep(rand(3..7))

    # Simulate more human-like behavior
    simulate_pre_search_behavior(driver)

    # Perform the search with typing simulation
    simulate_typing_search(driver)

    # Wait for results and handle potential captcha
    wait = Selenium::WebDriver::Wait.new(timeout: 30)
    begin
      wait.until do
        page_loaded = check_page_loaded(driver)
        return nil unless handle_captcha(driver)
        page_loaded
      end

      # More natural reading behavior
      simulate_reading_behavior(driver)

      # Get and verify the content
      doc = Nokogiri::HTML(driver.page_source)

      if valid_search_results?(doc)
        doc
      else
        nil
      end
    rescue Selenium::WebDriver::Error::TimeoutError => e
      handle_timeout_error(driver, e)
    end
  end

  def inject_stealth_scripts(driver)
    # Inject scripts to mask automation
    driver.execute_script(<<~JS)
      // Overwrite navigator properties
      Object.defineProperty(navigator, 'webdriver', { get: () => false });
      Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });

      // Add missing chrome properties
      window.chrome = {
        runtime: {},
        loadTimes: function() {},
        csi: function() {},
        app: {}
      };

      // Modify permissions
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );
    JS
  end

  def simulate_typing_search(driver)
    begin
      # Find search box
      search_box = driver.find_element(name: "q")
      search_box.click
      sleep(rand(0.5..1.5))

      # Type the search query with random delays between characters
      @keyword.name.each_char do |char|
        search_box.send_keys(char)
        sleep(rand(0.1..0.3))
      end

      sleep(rand(0.5..1.5))
      search_box.send_keys(:return)
    rescue StandardError => e
      Rails.logger.error "Error during typing simulation: #{e.message}"
      # Fallback to direct navigation if typing fails
      search_query = URI.encode_www_form_component(@keyword.name)
      driver.navigate.to "https://www.google.com/search?q=#{search_query}&hl=en"
    end
  end

  def simulate_pre_search_behavior(driver)
    # Move mouse to random positions
    3.times do
      x = rand(100..800)
      y = rand(100..600)
      driver.execute_script(<<~JS)
        document.elementFromPoint(#{x}, #{y})?.dispatchEvent(
          new MouseEvent('mouseover', {
            bubbles: true,
            cancelable: true,
            view: window
          })
        );
      JS
      sleep(rand(0.3..0.8))
    end

    # Random scrolling
    2.times do
      scroll_amount = rand(100..300) * (rand > 0.5 ? 1 : -1)
      driver.execute_script("window.scrollBy(0, #{scroll_amount})")
      sleep(rand(0.5..1.2))
    end
  end

  def visit_random_sites(driver)
    INTERMEDIATE_SITES.sample(rand(2..3)).each do |site|
      driver.navigate.to site
      sleep(rand(3..7))

      # Simulate reading
      total_height = driver.execute_script("return document.body.scrollHeight")
      scroll_positions = (0..total_height).step(rand(200..400)).to_a

      scroll_positions.each do |pos|
        driver.execute_script("window.scrollTo(0, #{pos})")
        sleep(rand(0.5..1.5))
      end
    end
  end

  def check_page_loaded(driver)
    [
      "div#search",
      "div#rso",
      "div#main",
      "div#center_col",
      "div.g"
    ].any? do |selector|
      driver.find_elements(css: selector).any?
    end
  end

  def valid_search_results?(doc)
    return false if doc.css("body").empty?
    return false if doc.text.include?("unusual traffic")
    return false if doc.text.include?("captcha")
    return false if doc.text.include?("automated requests")
    return false unless doc.css("div#search").any?
    true
  end

  def handle_captcha(driver)
    if driver.page_source.include?("captcha") || driver.page_source.include?("unusual traffic")
      Rails.logger.warn "Captcha detected for keyword: #{@keyword.name}"
      sleep(rand(10..20))  # Wait longer before retry
      return false
    end
    true
  end

  def handle_search_error(error)
    Rails.logger.error "Search error for keyword '#{@keyword.name}': #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    sleep(rand(20..40))  # Longer delay after error
  end

  def rotate_proxy
    @proxies = fetch_proxies
  end

  def fetch_proxies
    begin
      # Use a more reliable free proxy list
      response = HTTParty.get("https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt", timeout: 10)

      if response.success?
        proxies = response.body.split("\n").map do |line|
          addr, port = line.strip.split(":")
          next unless addr && port
          OpenStruct.new(
            addr: addr,
            port: port,
            working?: true
          )
        end.compact

        Rails.logger.info "Fetched #{proxies.length} proxies"
        proxies
      else
        Rails.logger.error "Failed to fetch proxies: HTTP #{response.code}"
        []
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching proxies: #{e.message}"
      # Return empty array if proxy fetching fails - will run without proxy
      []
    end
  end

  def simulate_reading_behavior(driver)
    # Scroll slowly down the page
    total_height = driver.execute_script("return document.body.scrollHeight")
    current_position = 0

    while current_position < total_height
      scroll_amount = rand(100..300)
      current_position += scroll_amount
      driver.execute_script("window.scrollTo(0, #{current_position})")
      sleep(rand(0.5..1.5))
    end

    # Scroll back up partially
    driver.execute_script("window.scrollTo(0, #{total_height/2})")
    sleep(rand(1..2))
  end

  def handle_timeout_error(driver, error)
    if driver.find_elements(tag_name: "body").any?
      Rails.logger.info "Found body element, proceeding with parsing"
      Nokogiri::HTML(driver.page_source)
    else
      raise error
    end
  end

  def extract_search_volume(doc)
    # Extract "About X results" from the page
    result_stats = doc.css("#result-stats").text
    if result_stats =~ /About ([\d,]+) results/
      $1.gsub(",", "").to_i
    end
  end


  def count_adwords_advertisers(doc)
    doc.css('div[data-text-ad="1"]').count
  end

  def count_total_links(doc)
    # Find all links with href attributes and extract their URLs
    links = doc.css("a[href]").map do |link|
      href = link["href"]
      next if href.nil? || href.empty? || href.start_with?("#", "javascript:")

      # Try to extract actual URL if it's a Google redirect
      if href.start_with?("/url?")
        extract_actual_url(href)
      else
        href
      end
    end.compact

    # Log the found links for debugging
    Rails.logger.info "Found #{links.length} valid links"
    Rails.logger.debug "Links found: #{links.join("\n")}"

    # Store links in search_metadata
    @keyword.search_metadata ||= {}
    @keyword.search_metadata["all_links"] = links

    # Return the count of valid links
    links.length
  end

  def extract_search_time(doc)
    # Extract search time from results
    result_stats = doc.css("#result-stats").text
    if result_stats =~ /\(([\d.]+) seconds\)/
      $1.to_f
    end
  end

  # Extract the actual URL from Google's redirect wrapper
  def extract_actual_url(google_url)
    uri = URI.parse(google_url.start_with?("http") ? google_url : "https://www.google.com#{google_url}")
    params = CGI.parse(uri.query || "")
    params["q"]&.first || params["url"]&.first || google_url
  rescue URI::InvalidURIError
    google_url
  end
end
