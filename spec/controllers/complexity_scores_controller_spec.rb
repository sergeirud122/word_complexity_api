# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ComplexityScoresController do
  describe 'POST #create' do
    let(:valid_words) { %w[happy sad excellent] }
    let(:batch_key) { 'batch:1234567890abcdef' }
    let(:job_id) { '1234567890abcdef' }

    before do
      allow(BatchKeyGenerator).to receive_messages(generate: batch_key, extract_job_id: job_id)
      allow(JobCacheService).to receive(:result_exists?).and_return(false)
      allow(JobCacheService).to receive(:mark_as_pending)
      allow(ComplexityScoreJob).to receive(:perform_later)
    end

    context 'with valid parameters' do
      let(:mock_form) { instance_double(WordsForm) }

      before do
        allow(WordsForm).to receive(:new).and_return(mock_form)
        allow(mock_form).to receive_messages(submit: true, processed_words: valid_words)
      end

      it 'creates a new job and returns job_id' do
        post :create, body: valid_words.to_json, as: :json

        expect(response).to have_http_status(:accepted)
        expect(response.parsed_body).to include('job_id' => job_id)
      end

      it 'uses existing result when available' do
        allow(JobCacheService).to receive(:result_exists?).and_return(true)

        post :create, body: valid_words.to_json, as: :json

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'with invalid array format' do
      it 'returns validation error' do
        post :create, body: '{"not": "array"}', as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_body = response.parsed_body
        expect(response_body['error']).to eq('Validation failed')
      end
    end
  end

  describe 'GET #show' do
    let(:valid_job_id) { '1234567890abcdef' }
    let(:invalid_job_id) { 'invalid' }
    let(:batch_key) { "batch:#{valid_job_id}" }

    context 'with valid job_id' do
      before do
        allow(JobCacheService).to receive(:get_job_status).and_return(job_status)
      end

      context 'when job is pending' do
        let(:job_status) { { status: 'pending' } }

        it 'returns pending status' do
          get :show, params: { id: valid_job_id }

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('status' => 'pending')
        end
      end

      context 'when job is completed' do
        let(:job_status) { { status: 'completed', result: { 'happy' => 5.0, 'sad' => 3.0 } } }

        it 'returns completed status with results' do
          get :show, params: { id: valid_job_id }

          expect(response).to have_http_status(:ok)
          response_body = response.parsed_body
          expect(response_body['status']).to eq('completed')
          expect(response_body['result']).to eq('happy' => 5.0, 'sad' => 3.0)
        end
      end

      context 'when job failed' do
        let(:job_status) { { status: 'failed' } }

        it 'returns failed status' do
          get :show, params: { id: valid_job_id }

          expect(response).to have_http_status(:unprocessable_entity)
          response_body = response.parsed_body
          expect(response_body['status']).to eq('failed')
        end
      end
    end

    context 'with invalid job_id' do
      it 'returns invalid job_id error' do
        get :show, params: { id: invalid_job_id }
        expect(response).to have_http_status(:bad_request)
        response_body = response.parsed_body
        expect(response_body['error']).to eq('Invalid job ID format')
      end
    end

    context 'when job not found' do
      before do
        allow(JobCacheService).to receive(:get_job_status).and_return(nil)
      end

      it 'returns job not found error' do
        get :show, params: { id: valid_job_id }

        expect(response).to have_http_status(:not_found)
        response_body = response.parsed_body
        expect(response_body['error']).to eq('Job not found')
      end
    end

    context 'with nil job_id' do
      it 'returns invalid job_id error' do
        get :show, params: { id: '' }

        expect(response).to have_http_status(:bad_request)
        response_body = response.parsed_body
        expect(response_body['error']).to eq('Invalid job ID format')
      end
    end
  end

  describe 'valid_job_id?' do
    it 'validates correct job_id format' do
      expect(controller.send(:valid_job_id?, '1234567890abcdef')).to be true
      expect(controller.send(:valid_job_id?, 'ABCDEF1234567890')).to be true
    end

    it 'rejects invalid job_id format' do
      expect(controller.send(:valid_job_id?, 'invalid')).to be false
      expect(controller.send(:valid_job_id?, '1234567890abcde')).to be false # too short
      expect(controller.send(:valid_job_id?, '1234567890abcdefg')).to be false  # too long
      expect(controller.send(:valid_job_id?, '1234567890abcdef@')).to be false  # invalid chars
      expect(controller.send(:valid_job_id?, nil)).to be false
      expect(controller.send(:valid_job_id?, '')).to be false
    end
  end
end
