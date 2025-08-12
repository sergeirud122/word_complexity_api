# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchCacheService, type: :service do
  let(:words) { %w[hello world test] }
  let(:results) { { 'hello' => 0.75, 'world' => 0.25, 'test' => 0.5 } }

  before do
    allow(Rails.cache).to receive(:read)
    allow(Rails.cache).to receive(:write)
    stub_const('CacheKeyGenerator', Class.new do
      def self.generate_for_words(_words)
        'abc123def456'
      end
    end)
  end

  describe '.get_cached_batch' do
    context 'with valid words' do
      it 'reads from cache with correct key' do
        described_class.get_cached_batch(words)

        expect(Rails.cache).to have_received(:read).with('batch:abc123def456')
      end

      it 'returns cached data when available' do
        allow(Rails.cache).to receive(:read).with('batch:abc123def456').and_return(results)

        result = described_class.get_cached_batch(words)

        expect(result).to eq(results)
      end

      it 'returns nil when no cached data' do
        allow(Rails.cache).to receive(:read).with('batch:abc123def456').and_return(nil)

        result = described_class.get_cached_batch(words)

        expect(result).to be_nil
      end
    end
  end

  describe '.cache_batch_result' do
    context 'with valid data' do
      it 'writes to cache with correct key and data' do
        described_class.cache_batch_result(words, results)

        expect(Rails.cache).to have_received(:write).with('batch:abc123def456', results, expires_in: 6.hours)
      end

      it 'writes empty results to cache' do
        empty_results = {}
        described_class.cache_batch_result(words, empty_results)

        expect(Rails.cache).to have_received(:write).with('batch:abc123def456', empty_results, expires_in: 6.hours)
      end

      it 'writes nil results to cache' do
        described_class.cache_batch_result(words, nil)

        expect(Rails.cache).to have_received(:write).with('batch:abc123def456', nil, expires_in: 6.hours)
      end
    end

    context 'with complex results' do
      let(:complex_results) do
        {
          'hello' => { score: 0.75, details: { synonyms: 5, antonyms: 2 } },
          'world' => { score: 0.25, details: { synonyms: 2, antonyms: 1 } },
        }
      end

      it 'writes complex results to cache' do
        described_class.cache_batch_result(words, complex_results)

        expect(Rails.cache).to have_received(:write).with('batch:abc123def456', complex_results, expires_in: 6.hours)
      end
    end
  end

  describe 'cache key generation' do
    it 'uses CacheKeyGenerator for key generation' do
      described_class.get_cached_batch(words)

      expect(Rails.cache).to have_received(:read).with('batch:abc123def456')
    end
  end
end
