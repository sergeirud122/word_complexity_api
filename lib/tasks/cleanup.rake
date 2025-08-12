# frozen_string_literal: true

namespace :jobs do
  desc 'Clean up expired Redis keys (automatic with TTL)'
  task cleanup: :environment do
    puts 'Redis cleanup information:'
    puts 'This application uses Redis TTL for automatic cleanup:'
    puts '  - job_status:* keys expire in 6 hours'
    puts '  - job_result:* keys expire in 6 hours'
    puts '  - word_score:* keys expire in 1 day'
    puts '  - batch:* keys expire in 6 hours'
    puts ''
    puts 'No manual cleanup needed - Redis handles expiration automatically.'
  end

  desc 'Show Redis statistics'
  task stats: :environment do
    puts '=== Redis Statistics ==='

    # Получаем информацию о ключах через Redis connection pool
    Rails.cache.redis.with do |redis|
      job_status_keys = redis.keys('job_status:*').count
      job_result_keys = redis.keys('job_result:*').count
      word_score_keys = redis.keys('word_score:*').count
      batch_keys = redis.keys('batch:*').count

      puts 'Current Redis keys:'
      puts "  Job statuses (pending/failed): #{job_status_keys}"
      puts "  Job results (completed): #{job_result_keys}"
      puts "  Word cache: #{word_score_keys}"
      puts "  Batch cache: #{batch_keys}"

      # Информация о памяти Redis
      redis_info = redis.info('memory')
      used_memory = redis_info['used_memory_human']
      puts "\nMemory usage: #{used_memory}"

      # Примеры ключей
      puts "\n=== Sample keys ==="
      sample_job_status = redis.keys('job_status:*').first(3)
      sample_word_scores = redis.keys('word_score:*').first(3)

      if sample_job_status.any?
        puts 'Job status keys:'
        sample_job_status.each { |key| puts "  #{key}" }
      end

      if sample_word_scores.any?
        puts 'Word score keys:'
        sample_word_scores.each { |key| puts "  #{key}" }
      end
    end
  rescue Redis::CannotConnectError
    puts 'Error: Cannot connect to Redis'
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end
