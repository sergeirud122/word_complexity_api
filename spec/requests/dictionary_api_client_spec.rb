# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DictionaryApiClient do
  describe '.fetch' do
    let(:word) { 'happy' }
    let(:api_url) { "https://api.dictionaryapi.dev/api/v2/entries/en/#{word}" }

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'when API call is successful' do
      let(:successful_response) do
        [
          {
            'word' => 'happy',
            'meanings' => [
              {
                'partOfSpeech' => 'adjective',
                'definitions' => [
                  {
                    'definition' => 'feeling or showing pleasure or contentment',
                    'synonyms' => %w[joyful cheerful],
                    'antonyms' => %w[sad unhappy],
                  },
                ],
                'synonyms' => %w[joyful cheerful glad],
                'antonyms' => %w[sad unhappy miserable],
              },
            ],
          },
        ]
      end

      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns parsed definitions' do
        result = described_class.fetch(word)

        expect(result).to include(:definitions)
        expect(result[:definitions]).to be_an(Array)
        expect(result[:definitions].first).to include(:synonyms, :antonyms)
      end

      it 'combines synonyms and antonyms from meaning and definition levels' do
        result = described_class.fetch(word)
        definition = result[:definitions].first

        expect(definition[:synonyms]).to include('joyful', 'cheerful')
        expect(definition[:antonyms]).to include('sad', 'unhappy')
      end

      it 'removes duplicates from synonyms and antonyms' do
        result = described_class.fetch(word)
        definition = result[:definitions].first

        expect(definition[:synonyms].uniq).to eq(definition[:synonyms])
        expect(definition[:antonyms].uniq).to eq(definition[:antonyms])
      end
    end

    context 'when API returns empty response' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: [].to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns empty definitions' do
        result = described_class.fetch(word)
        expect(result).to eq(definitions: [])
      end
    end

    context 'when API returns nil response' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: nil,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns empty definitions' do
        result = described_class.fetch(word)
        expect(result).to eq(definitions: [])
      end
    end

    context 'when API returns 404' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises an error with status code' do
        expect { described_class.fetch(word) }.to raise_error(/Dictionary API Error: 404/)
      end
    end

    context 'when API returns 500' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an error with status code' do
        expect { described_class.fetch(word) }.to raise_error(/Dictionary API Error: 500/)
      end
    end

    context 'when network timeout occurs' do
      before do
        stub_request(:get, api_url).to_timeout
      end

      it 'raises network error' do
        expect { described_class.fetch(word) }.to raise_error(/Network error/)
      end
    end

    context 'when HTTParty raises an error' do
      before do
        stub_request(:get, api_url).to_raise(HTTParty::Error.new('Connection failed'))
      end

      it 'raises network error' do
        expect { described_class.fetch(word) }.to raise_error(/Network error/)
      end
    end

    context 'when unexpected error occurs' do
      before do
        stub_request(:get, api_url).to_raise(StandardError.new('Unexpected error'))
      end

      it 'raises API error' do
        expect { described_class.fetch(word) }.to raise_error(/API error/)
      end
    end
  end

  describe '.parse_response' do
    context 'with valid response data' do
      let(:response_data) do
        [
          {
            'word' => 'test',
            'meanings' => [
              {
                'definitions' => [
                  {
                    'synonyms' => %w[synonym1 synonym2],
                    'antonyms' => %w[antonym1],
                  },
                ],
                'synonyms' => %w[synonym3],
                'antonyms' => %w[antonym2],
              },
            ],
          },
        ]
      end

      it 'parses definitions correctly' do
        result = described_class.parse_response(response_data)

        expect(result).to include(:definitions)
        expect(result[:definitions]).to be_an(Array)
        expect(result[:definitions].first).to include(:synonyms, :antonyms)
      end

      it 'combines synonyms and antonyms from both levels' do
        result = described_class.parse_response(response_data)
        definition = result[:definitions].first

        expect(definition[:synonyms]).to include('synonym1', 'synonym2', 'synonym3')
        expect(definition[:antonyms]).to include('antonym1', 'antonym2')
      end

      it 'removes duplicates' do
        result = described_class.parse_response(response_data)
        definition = result[:definitions].first

        expect(definition[:synonyms].uniq).to eq(definition[:synonyms])
        expect(definition[:antonyms].uniq).to eq(definition[:antonyms])
      end
    end

    context 'with empty response data' do
      it 'returns empty definitions for nil' do
        result = described_class.parse_response(nil)
        expect(result).to eq(definitions: [])
      end

      it 'returns empty definitions for empty array' do
        result = described_class.parse_response([])
        expect(result).to eq(definitions: [])
      end

      it 'returns empty definitions for blank response' do
        result = described_class.parse_response('')
        expect(result).to eq(definitions: [])
      end
    end

    context 'with invalid response structure' do
      it 'returns empty definitions when no meanings' do
        response_data = [{ 'word' => 'test' }]
        result = described_class.parse_response(response_data)
        expect(result).to eq(definitions: [])
      end

      it 'returns empty definitions when meanings is nil' do
        response_data = [{ 'word' => 'test', 'meanings' => nil }]
        result = described_class.parse_response(response_data)
        expect(result).to eq(definitions: [])
      end

      it 'handles missing definitions array' do
        response_data = [{ 'word' => 'test', 'meanings' => [{ 'synonyms' => ['test'] }] }]
        result = described_class.parse_response(response_data)
        expect(result).to eq(definitions: [])
      end
    end
  end

  describe '.extract_words' do
    it 'returns valid words from array' do
      words = ['valid', '', nil, 'another', 123, 'word']
      result = described_class.extract_words(words)
      expect(result).to eq(%w[valid another word])
    end

    it 'returns empty array for nil input' do
      result = described_class.extract_words(nil)
      expect(result).to eq([])
    end

    it 'returns empty array for non-array input' do
      result = described_class.extract_words('not an array')
      expect(result).to eq([])
    end

    it 'returns empty array for empty array' do
      result = described_class.extract_words([])
      expect(result).to eq([])
    end

    it 'filters out non-string elements' do
      words = [123, nil, '', 'valid', { hash: 'value' }]
      result = described_class.extract_words(words)
      expect(result).to eq(['valid'])
    end
  end
end
