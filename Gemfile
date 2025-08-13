# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.2'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

# HTTP requests для Dictionary API
gem 'httparty', '~> 0.21'

# Redis для кэша (единственное хранилище)
gem 'hiredis', '~> 0.6'
gem 'redis', '~> 5.0'

# Background job processing (для production)
gem 'sidekiq', '~> 7.2'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop-rails-omakase', require: false

  gem 'rspec-rails', '~> 6.0'
  gem 'webmock', '~> 3.19'

  gem 'rswag-api'
  gem 'rswag-specs'
  gem 'rswag-ui'

  # Advanced Linters & Code Quality
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-capybara', '~> 2.20', require: false
  gem 'rubocop-factory_bot', '~> 2.25', require: false
  gem 'rubocop-performance', '~> 1.20', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false
  gem 'rubocop-thread_safety', '~> 0.5', require: false

  # Security & Code Analysis
  gem 'bundler-audit', '~> 0.9', require: false # Security vulnerabilities
  gem 'rails_best_practices', '~> 1.23', require: false
  gem 'reek', '~> 6.1', require: false          # Code smell detection

  # Documentation & Metrics
  gem 'flay', '~> 2.13', require: false         # Code duplication detection
  gem 'flog', '~> 4.6', require: false          # Code complexity
  gem 'yard', '~> 0.9', require: false          # Documentation generation
end

# group :test do
# end
