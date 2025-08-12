# frozen_string_literal: true

require 'digest'

module WordProcessing
  module_function

  # Public API - только вычисления сложности

  def calculate_score_from_data(api_data)
    definitions = api_data[:definitions] || []
    return 0.0 if definitions.empty?

    synonyms_count = definitions.sum { |d| d[:synonyms].count }
    antonyms_count = definitions.sum { |d| d[:antonyms].count }

    ((synonyms_count + antonyms_count).to_f / definitions.count).round(2)
  end

  def get_cached_score(word)
    Rails.cache.read(cache_key_for(word))
  end

  def cache_word_score(word, score)
    Rails.cache.write(cache_key_for(word), score, expires_in: 1.day)
  end

  def cache_key_for(word)
    "word_score:#{word.downcase}"
  end
end
