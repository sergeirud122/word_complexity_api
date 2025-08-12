# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchKeyGenerator, type: :service do
  let(:words) { %w[hello world test] }
  let(:batch_key) { 'batch:abc123def456' }

  describe '.generate' do
    it 'generates key from words' do
      result = described_class.generate(words)

      expect(result).to start_with('batch:')
      expect(result.length).to eq(22)
    end

    it 'generates same key for same sorted words' do
      key_one = described_class.generate(%w[hello test world])
      key_two = described_class.generate(%w[hello test world])

      expect(key_one).to eq(key_two)
    end

    it 'generates different keys for different words' do
      key_one = described_class.generate(%w[hello world])
      key_two = described_class.generate(%w[hello world test])

      expect(key_one).not_to eq(key_two)
    end
  end

  describe '.extract_job_id' do
    it 'extracts job id from batch key' do
      result = described_class.extract_job_id(batch_key)

      expect(result).to eq('abc123def456')
    end

    it 'handles different batch keys' do
      result = described_class.extract_job_id('batch:xyz789abc123')

      expect(result).to eq('xyz789abc123')
    end

    it 'handles empty job id' do
      result = described_class.extract_job_id('batch:')

      expect(result).to eq('')
    end

    it 'handles long job id' do
      long_key = "batch:#{'a' * 100}"
      result = described_class.extract_job_id(long_key)

      expect(result).to eq('a' * 100)
    end
  end
end
