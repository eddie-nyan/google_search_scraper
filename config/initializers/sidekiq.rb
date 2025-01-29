require "sidekiq/throttled"

# Configure Redis connection
redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  config.redis = redis_config
end

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  config.redis = redis_config
end
