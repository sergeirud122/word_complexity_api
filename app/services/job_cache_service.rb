# frozen_string_literal: true

module JobCacheService
  module_function

  # Public API

  def result_exists?(batch_key)
    job_id = extract_job_id(batch_key)
    Rails.cache.exist?(result_key(job_id))
  end

  def get_job_status(batch_key)
    job_id = extract_job_id(batch_key)

    result = Rails.cache.read(result_key(job_id))
    return { status: 'completed', result: result } if result

    status_data = Rails.cache.read(status_key(job_id))
    case status_data
    when 'pending'
      { status: 'pending' }
    when 'failed'
      { status: 'failed' }
    end
  end

  def mark_as_pending(batch_key)
    job_id = extract_job_id(batch_key)
    Rails.cache.write(status_key(job_id), 'pending', expires_in: 6.hours)
  end

  def mark_as_failed(batch_key)
    job_id = extract_job_id(batch_key)
    Rails.cache.write(status_key(job_id), 'failed', expires_in: 6.hours)
  end

  def save_results(batch_key, results)
    job_id = extract_job_id(batch_key)
    Rails.cache.write(result_key(job_id), results, expires_in: 6.hours)
    Rails.cache.delete(status_key(job_id))
  end

  def get_results(batch_key)
    job_id = extract_job_id(batch_key)
    Rails.cache.read(result_key(job_id))
  end

  # Internal helper methods

  def extract_job_id(batch_key)
    batch_key.sub('batch:', '')
  end

  def status_key(job_id)
    "job_status:#{job_id}"
  end

  def result_key(job_id)
    "job_result:#{job_id}"
  end
end
