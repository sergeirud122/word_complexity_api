require_relative "boot"

# Load Rails components without ActiveRecord
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/railtie"  # Не нужно для API-only приложения
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WordComplexityApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`.
    config.autoload_lib(ignore: %w[assets tasks])

    # Autoload forms directory
    config.eager_load_paths += %W(#{config.root}/app/forms)

    # Autoload requests directory
    config.eager_load_paths += %W(#{config.root}/app/requests)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like ActionDispatch::Session::CookieStore, ActionDispatch::Flash, and ActionDispatch::Stack
    # are added back under test environment for RSwag specs
    config.api_only = true

    # Accept requests from any origin (for testing)
    config.force_ssl = false
    
    # Skip ActiveRecord for generators
    config.generators do |g|
      g.orm false
    end
  end
end
