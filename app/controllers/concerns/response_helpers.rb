# frozen_string_literal: true

module ResponseHelpers
  extend ActiveSupport::Concern

  # Методы для стандартизированных ответов

  # Простой метод для рендеринга ошибок
  def render_error(message, status: 400, **details)
    render json: {
      error: message,
      **details,
    }, status: status
  end
end
