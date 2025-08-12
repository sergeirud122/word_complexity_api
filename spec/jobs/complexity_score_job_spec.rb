# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ComplexityScoreJob do
  let(:words) { %w[happy sad] }
  let(:batch_key) { 'test_batch_key_123' }

  describe '#perform' do
    before do
      allow(WordProcessing).to receive_messages(get_cached_score: nil, calculate_score_from_data: 0.75)
      allow(WordProcessing).to receive(:cache_word_score)
      allow(DictionaryApiClient).to receive(:fetch).and_return({ definitions: [{ synonyms: ['test'], antonyms: [] }] })
      allow(JobCacheService).to receive(:save_results)
      allow(JobCacheService).to receive(:mark_as_failed)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
      allow(Rails.logger).to receive(:warn)
    end

    it 'processes each word individually' do
      described_class.perform_now(words, batch_key)

      words.each do |word|
        expect(WordProcessing).to have_received(:get_cached_score).with(word)
      end
    end

    it 'saves results through JobCacheService' do
      described_class.perform_now(words, batch_key)

      expect(JobCacheService).to have_received(:save_results).with(batch_key, { 'happy' => 0.75, 'sad' => 0.75 })
    end

    it 'fetches data from API for uncached words' do
      described_class.perform_now(words, batch_key)

      words.each do |word|
        expect(DictionaryApiClient).to have_received(:fetch).with(word)
      end
    end

    it 'uses cached scores when available' do
      allow(WordProcessing).to receive(:get_cached_score).with('happy').and_return(0.5)

      described_class.perform_now(words, batch_key)

      expect(DictionaryApiClient).to have_received(:fetch).with('sad')
      expect(DictionaryApiClient).not_to have_received(:fetch).with('happy')
    end

    context 'when processing succeeds' do
      it 'completes successfully without errors' do
        expect { described_class.perform_now(words, batch_key) }.not_to raise_error
      end
    end

    context 'when API request fails' do
      before do
        allow(DictionaryApiClient).to receive(:fetch).and_raise(StandardError.new('API error'))
        # Отключаем retry для тестов
        allow(described_class).to receive(:retry_on).and_return(nil)
      end

      it 'handles API errors gracefully with fallback data' do
        expect { described_class.perform_now(words, batch_key) }.not_to raise_error
      end

      it 'logs warning for API failures' do
        described_class.perform_now(words, batch_key)

        words.each do |word|
          expect(Rails.logger).to have_received(:warn).with(/Failed to fetch data for word '#{word}'/)
        end
      end
    end

    context 'when processing fails' do
      before do
        allow(WordProcessing).to receive(:calculate_score_from_data).and_raise(StandardError.new('Processing error'))
        # Отключаем retry для тестов
        allow(described_class).to receive(:retry_on).and_return(nil)
      end

      it 'marks job as failed through JobCacheService' do
        begin
          described_class.perform_now(words, batch_key)
        rescue StandardError
          # Игнорируем ошибку для проверки кэша
        end

        expect(JobCacheService).to have_received(:mark_as_failed).with(batch_key)
      end

      it 're-raises the error' do
        expect { described_class.perform_now(words, batch_key) }.to raise_error(StandardError)
      end
    end

    context 'with empty words array' do
      let(:words) { [] }

      it 'handles empty array gracefully' do
        expect { described_class.perform_now(words, batch_key) }.not_to raise_error
      end
    end

    context 'with single word' do
      let(:words) { ['hello'] }

      it 'processes single word correctly' do
        described_class.perform_now(words, batch_key)

        expect(WordProcessing).to have_received(:get_cached_score).with('hello')
        expect(DictionaryApiClient).to have_received(:fetch).with('hello')
      end
    end
  end
end
