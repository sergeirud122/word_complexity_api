# frozen_string_literal: true

module BatchCacheService
  module_function

  # Public API

  def get_cached_batch(words)
    cache_key = generate_cache_key(words)
    Rails.cache.read(cache_key)
  end

  def cache_batch_result(words, results)
    cache_key = generate_cache_key(words)
    Rails.cache.write(cache_key, results, expires_in: 6.hours)
  end

  # Internal helper methods

  def generate_cache_key(words)
    hash = CacheKeyGenerator.generate_for_words(words)
    "batch:#{hash}"
  end
end
