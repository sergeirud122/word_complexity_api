# frozen_string_literal: true

module SimpleErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_error
  end

  private

  def handle_error(error)
    status, code, message = case error
                            when ActionController::ParameterMissing
                              [400, :missing_parameter, "Missing parameter: #{error.param}"]
                            when JSON::ParserError
                              [400, :invalid_json, 'Invalid JSON format']
                            when Redis::BaseError
                              [503, :service_unavailable, 'Service temporarily unavailable']
                            when Timeout::Error
                              [504, :timeout, 'Request timeout']
                            else
                              Rails.logger.error "#{error.class}: #{error.message}"
                              Rails.logger.error error.backtrace.join("\n") if Rails.env.development?
                              [500, :internal_error, 'Internal server error']
                            end

    render json: {
      success: false,
      status: status,
      error: {
        code: code,
        message: message,
        timestamp: Time.current.iso8601,
      },
    }, status: status
  end
end
