# frozen_string_literal: true

class BaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Общие методы для всех форм
  def submit
    valid?
  end

  def error_details
    return {} unless errors.any?

    errors.details.transform_values do |error_array|
      error_array.map { |error| error[:error] || 'invalid' }
    end
  end

  def formatted_errors
    return {} unless errors.any?

    {
      summary: errors.full_messages,
      details: error_details,
      count: errors.count,
    }
  end

  protected

  # Валидация UUID
  def valid_uuid?(uuid)
    uuid_pattern = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    uuid.to_s.match?(uuid_pattern)
  end

  # Валидация формата слова
  def valid_word_format?(word)
    return false if word.blank?
    return false if word.length > 50
    return false unless word.match?(/\A[a-zA-Z\-'\s]+\z/)

    true
  end

  # Очистка строки
  def sanitize_string(string, max_length: 255)
    return nil if string.blank?

    string.to_s.strip.truncate(max_length)
  end
end
