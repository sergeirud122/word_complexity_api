# frozen_string_literal: true

require 'timeout'

class ComplexityScoreJob < ApplicationJob
  queue_as :complexity_calculation

  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  retry_on Timeout::Error, wait: 5.seconds, attempts: 3

  def perform(words, batch_key)
    Rails.logger.info "ComplexityScoreJob: Starting processing for #{words.size} words"

    results = {}

    words.each do |word|
      results[word] = process_word(word)
    end

    # Сохраняем результат (статус pending автоматически удалится)
    JobCacheService.save_results(batch_key, results)

    Rails.logger.info "ComplexityScoreJob: Completed processing and cached results for #{words.size} words"
  rescue StandardError => e
    Rails.logger.error "ComplexityScoreJob: Error processing words: #{e.message}"

    # Отмечаем джоб как провалившийся
    JobCacheService.mark_as_failed(batch_key)

    raise e
  end

  private

  def process_word(word)
    # Проверяем кэш
    cached_score = WordProcessing.get_cached_score(word)
    return cached_score if cached_score

    # Запрашиваем данные из API
    api_data = fetch_word_data(word)

    # Вычисляем сложность
    score = WordProcessing.calculate_score_from_data(api_data)

    # Кэшируем результат при желании это можно хранить вечно в postgres
    # TODO: добавить postgres :)
    WordProcessing.cache_word_score(word, score)

    score
  end

  def fetch_word_data(word)
    DictionaryApiClient.fetch(word)
  rescue StandardError => e
    Rails.logger.warn "Failed to fetch data for word '#{word}': #{e.message}"
    { definitions: [] }
  end
end
