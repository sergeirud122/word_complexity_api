# frozen_string_literal: true

class WordsForm < BaseForm
  MAX_WORDS_PER_REQUEST = 100
  MIN_WORD_LENGTH = 1
  MAX_WORD_LENGTH = 50

  attribute :words, array: true
  attribute :raw_request_body, :string

  validate :validate_raw_request_body
  validate :validate_words_array
  validate :validate_words_count
  validate :validate_words_format

  def submit
    return false unless valid?

    # Нормализуем слова - убираем nil и обрезаем длинные
    self.words = words.filter_map { |word| sanitize_string(word, max_length: MAX_WORD_LENGTH) }

    true
  end

  def processed_words
    return [] unless valid?

    words.uniq.sort
  end

  private

  def validate_raw_request_body
    if raw_request_body.present?
      parse_json_body
    elsif words.blank?
      errors.add(:base, 'Request body is required', type: :missing_request_body)
    end
  end

  def parse_json_body
    parsed = JSON.parse(raw_request_body)

    if parsed.is_a?(Array)
      self.words = parsed
    else
      errors.add(:base, 'Request must be a JSON array of words', type: :invalid_json_format)
    end
  rescue JSON::ParserError
    errors.add(:base, 'Invalid JSON format', type: :invalid_json)
  end

  def validate_words_array
    return errors.add(:words, 'Words array is required', type: :words_missing) if words.nil?
    return errors.add(:words, 'Must be an array', type: :not_array) unless words.is_a?(Array)
    return errors.add(:words, 'Array cannot be empty', type: :empty_array) if words.empty?

    # Проверяем что все элементы - строки
    words.each_with_index do |word, index|
      next if word.is_a?(String)

      errors.add(:words, "Word at position #{index} must be a string, got #{word.class.name}",
                 type: :invalid_type, position: index)
    end
  end

  def validate_words_count
    return unless words.present? && words.is_a?(Array)
    return if words.size <= MAX_WORDS_PER_REQUEST

    errors.add(:words, "Too many words. Maximum #{MAX_WORDS_PER_REQUEST} allowed, got #{words.size}",
               type: :too_many_words, max_allowed: MAX_WORDS_PER_REQUEST, received: words.size)
  end

  def validate_words_format
    return unless words.present? && words.is_a?(Array)

    invalid_words = words.filter_map.with_index do |word, index|
      next unless word.is_a?(String)

      reason = if word.blank?
                 'empty_word'
               elsif word.length < MIN_WORD_LENGTH
                 'too_short'
               elsif word.length > MAX_WORD_LENGTH
                 'too_long'
               elsif !valid_word_format?(word)
                 'invalid_format'
               end

      { position: index, word: word, reason: reason } if reason
    end

    return if invalid_words.empty?

    errors.add(:words, 'Contains invalid words', type: :invalid_format, invalid_words: invalid_words)
  end
end
