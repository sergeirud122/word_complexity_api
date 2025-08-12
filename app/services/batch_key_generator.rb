# frozen_string_literal: true

require 'digest'

module BatchKeyGenerator
  module_function

  # Public API

  def generate(words)
    hash = Digest::SHA256.hexdigest(words.join(','))
    "batch:#{hash[0..15]}"
  end

  def extract_job_id(batch_key)
    batch_key.sub('batch:', '')
  end
end
