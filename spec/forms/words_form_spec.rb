# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WordsForm, type: :form do
  let(:valid_words) { %w[hello world test] }

  describe '#submit' do
    context 'with valid data' do
      let(:form) { described_class.new(words: valid_words) }

      it 'returns true when form is valid' do
        expect(form.submit).to be true
        expect(form.errors).to be_empty
      end

      it 'normalizes data after validation' do
        form.submit
        expect(form.words).to eq(valid_words)
      end
    end

    context 'with invalid data' do
      let(:form) { described_class.new(words: nil) }

      it 'returns false when form is invalid' do
        expect(form.submit).to be false
        expect(form.errors).not_to be_empty
      end
    end
  end

  describe '#processed_words' do
    context 'with valid form' do
      let(:form) { described_class.new(words: %w[world hello world]) }

      before { form.submit }

      it 'returns unique sorted words' do
        expect(form.processed_words).to eq(%w[hello world])
      end
    end

    context 'with invalid form' do
      let(:form) { described_class.new(words: nil) }

      it 'returns empty array for invalid form' do
        expect(form.processed_words).to eq([])
      end
    end
  end

  describe 'validations' do
    context 'words validation' do
      it 'requires words to be present' do
        form = described_class.new(words: nil)
        form.submit

        expect(form.errors[:words]).to include('Words array is required')
      end

      it 'requires words to be an array' do
        form = described_class.new(words: 'not an array')
        form.submit

        expect(form.errors[:words]).to include('Must be an array')
      end

      it 'rejects empty arrays' do
        form = described_class.new(words: [])
        form.submit

        expect(form.errors[:words]).to include('Array cannot be empty')
      end

      it 'rejects too many words' do
        too_many_words = Array.new(101) { 'word' }
        form = described_class.new(words: too_many_words)
        form.submit

        expect(form.errors[:words]).to include(match(/Too many words/))
      end

      it 'rejects non-string elements' do
        form = described_class.new(words: ['valid', 123, 'word'])
        form.submit

        expect(form.errors[:words]).to include(match(/must be a string/))
      end

      it 'rejects words with invalid format' do
        form = described_class.new(words: ['valid', 'inv@lid', 'word'])
        form.submit

        expect(form.errors[:words]).to include('Contains invalid words')
      end

      it 'rejects empty words' do
        form = described_class.new(words: ['valid', '', 'word'])
        form.submit

        expect(form.errors[:words]).to include('Contains invalid words')
      end

      it 'rejects words that are too long' do
        long_word = 'a' * 51
        form = described_class.new(words: ['valid', long_word])
        form.submit

        expect(form.errors[:words]).to include('Contains invalid words')
      end

      it 'accepts valid word formats' do
        valid_words = ['hello', "world's", 'co-operation', 'multiple words']
        form = described_class.new(words: valid_words)

        expect(form.submit).to be true
      end
    end

    context 'raw_request_body validation' do
      it 'parses valid JSON array' do
        form = described_class.new(raw_request_body: valid_words.to_json)
        form.submit

        expect(form.submit).to be true
        expect(form.words).to eq(valid_words)
      end

      it 'rejects non-array JSON' do
        form = described_class.new(raw_request_body: '{"not": "array"}')
        form.submit

        expect(form.errors[:base]).to include('Request must be a JSON array of words')
      end

      it 'rejects invalid JSON' do
        form = described_class.new(raw_request_body: 'invalid json')
        form.submit

        expect(form.errors[:base]).to include('Invalid JSON format')
      end

      it 'requires request body when words are blank' do
        form = described_class.new(raw_request_body: '', words: nil)
        form.submit

        expect(form.errors[:base]).to include('Request body is required')
      end
    end
  end
end
