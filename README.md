# Google Search Scraper

A Ruby on Rails application that scrapes Google search results for keywords and provides analytics data including search volume, advertisers count, and total links.

## Requirements

- Ruby 3.3.6
- Rails 8.0.1
- PostgreSQL
- Redis (for Sidekiq)
- Chrome/Chromium (for Selenium WebDriver)

## Chrome WebDriver Setup

### macOS
Using Homebrew
``` bash
brew install --cask google-chrome
brew install chromedriver
```

### Linux (Ubuntu/Debian)
``` bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f
```

``` bash
sudo apt-get install chromium-chromedriver
```

``` bash
chromedriver --version
```

### Windows
1. Download and install Google Chrome from [official website](https://www.google.com/chrome/)
2. Download ChromeDriver from [ChromeDriver Downloads](https://sites.google.com/chromium.org/driver/)
3. Extract the downloaded file and add its location to your system's PATH
4. Verify installation by running `chromedriver --version` in Command Prompt

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/google-search-scraper.git
cd google-search-scraper
```

2. Install dependencies
```bash
bundle install
```

3. Setup database
```bash
rails db:create
rails db:migrate
```

4. Compile assets
```bash
rails assets:precompile
```

## Running the Application

1. Start Redis server (if not running)
```bash
redis-server
```

2. Start Sidekiq (required for background jobs)
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

3. Start Rails server
```bash
rails server
```

4. Visit `http://localhost:3000` in your browser

## Features

- User authentication with Devise
- Upload CSV files containing keywords (max 100 keywords per file)
- Automated Google search scraping for each keyword
- Track search volume, advertisers count, and total links
- Download results in CSV format
- Progress tracking for keyword processing
- RESTful API with JWT authentication
- Background job processing with Sidekiq
- Rate limiting for Google searches

## API Endpoints

### Authentication
```bash
# Sign in and get JWT token
POST /api/v1/sign_in
Content-Type: application/json
{
  "user": {
    "email": "user@example.com",
    "password": "password"
  }
}
```

### Keyword Files
```bash
# Upload keyword file
POST /api/v1/keyword_files
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data
Form params: keyword_file[file]=@path/to/file.csv

# Get keywords for a file
GET /api/v1/keyword_files/:id/keywords
Authorization: Bearer YOUR_JWT_TOKEN
```

## Testing

Run the test suite:
```bash
bundle exec rspec
```

## Development

The application uses:
- Tailwind CSS for styling
- Stimulus.js for JavaScript interactions
- Selenium WebDriver for web scraping
- Sidekiq for background job processing
- JWT for API authentication
- RSpec for testing

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details