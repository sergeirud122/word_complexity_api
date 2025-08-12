# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WordProcessing, type: :service do
  let(:word) { 'hello' }

  before do
    allow(Rails.cache).to receive(:read)
    allow(Rails.cache).to receive(:write)
  end

  describe '.calculate_score_from_data' do
    context 'with valid API data' do
      let(:api_data) do
        {
          definitions: [
            { synonyms: %w[happy joyful], antonyms: ['sad'] },
            { synonyms: ['glad'], antonyms: %w[unhappy depressed] },
          ],
        }
      end

      it 'calculates complexity score correctly' do
        result = described_class.calculate_score_from_data(api_data)

        # (2 + 1 + 1 + 2) synonyms and antonyms / 2 definitions = 3.0
        expect(result).to eq(3.0)
      end
    end

    context 'with empty definitions' do
      let(:api_data) { { definitions: [] } }

      it 'returns 0.0 for empty definitions' do
        result = described_class.calculate_score_from_data(api_data)

        expect(result).to eq(0.0)
      end
    end

    context 'with missing definitions key' do
      let(:api_data) { {} }

      it 'returns 0.0 for missing definitions' do
        result = described_class.calculate_score_from_data(api_data)

        expect(result).to eq(0.0)
      end
    end

    context 'with nil API data' do
      let(:api_data) { { definitions: nil } }

      it 'returns 0.0 for nil definitions' do
        result = described_class.calculate_score_from_data(api_data)

        expect(result).to eq(0.0)
      end
    end
  end

  describe '.get_cached_score' do
    it 'reads score from cache' do
      allow(Rails.cache).to receive(:read).with('word_score:hello').and_return(0.75)

      result = described_class.get_cached_score(word)

      expect(result).to eq(0.75)
    end

    it 'returns nil when not cached' do
      allow(Rails.cache).to receive(:read).with('word_score:hello').and_return(nil)

      result = described_class.get_cached_score(word)

      expect(result).to be_nil
    end
  end

  describe '.cache_word_score' do
    it 'writes score to cache with correct key and expiration' do
      described_class.cache_word_score(word, 0.75)

      expect(Rails.cache).to have_received(:write).with(
        'word_score:hello',
        0.75,
        expires_in: 1.day,
      )
    end
  end

  describe '.cache_key_for' do
    it 'generates correct cache key' do
      result = described_class.cache_key_for('Hello')

      expect(result).to eq('word_score:hello')
    end

    it 'handles uppercase words' do
      result = described_class.cache_key_for('WORLD')

      expect(result).to eq('word_score:world')
    end
  end
end
