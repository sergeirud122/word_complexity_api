# frozen_string_literal: true

require 'timeout'

class DictionaryApiClient
  include HTTParty

  base_uri 'https://api.dictionaryapi.dev/api/v2/entries/en'

  def self.fetch(word)
    response = get("/#{word}", timeout: 10)

    unless response.success?
      raise "Dictionary API Error: #{response.code} - #{response.message}"
    end

    parse_response(response.parsed_response)
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error "Network error fetching word '#{word}': #{e.message}"
    raise "Network error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error fetching word '#{word}': #{e.message}"
    raise "API error: #{e.message}"
  end

  def self.parse_response(response_data)
    return { definitions: [] } if response_data.blank? || !response_data.is_a?(Array)

    first_entry = response_data.first
    return { definitions: [] } unless first_entry&.dig('meanings')

    definitions = first_entry['meanings'].flat_map do |meaning|
      meaning_synonyms = extract_words(meaning['synonyms'])
      meaning_antonyms = extract_words(meaning['antonyms'])

      meaning['definitions']&.map do |definition|
        definition_synonyms = extract_words(definition['synonyms'])
        definition_antonyms = extract_words(definition['antonyms'])

        {
          synonyms: (definition_synonyms + meaning_synonyms).uniq,
          antonyms: (definition_antonyms + meaning_antonyms).uniq,
        }
      end
    end.compact

    { definitions: definitions }
  end

  def self.extract_words(words_array)
    return [] unless words_array.is_a?(Array)

    words_array.select { |word| word.is_a?(String) && word.present? }
  end
end
