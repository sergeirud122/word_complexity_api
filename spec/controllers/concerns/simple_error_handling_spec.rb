# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SimpleErrorHandling do
  # Создаем тестовый контроллер с маршрутами
  controller(ActionController::Base) do
    include SimpleErrorHandling

    def test_action
      raise params[:error_type].constantize, params[:message]
    end
  end

  # Добавляем маршруты для тестового контроллера
  before do
    routes.draw do
      get 'test_action' => 'anonymous#test_action'
    end
  end

  describe '#handle_error' do
    context 'when ActionController::ParameterMissing error occurs' do
      it 'returns 400 status with missing_parameter code' do
        get :test_action, params: { error_type: 'ActionController::ParameterMissing', message: 'param' }

        expect(response).to have_http_status(:bad_request)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(400)
        expect(response_body['error']['code']).to eq('missing_parameter')
        expect(response_body['error']['message']).to eq('Missing parameter: param')
        expect(response_body['error']['timestamp']).to be_present
      end
    end

    context 'when JSON::ParserError error occurs' do
      it 'returns 400 status with invalid_json code' do
        get :test_action, params: { error_type: 'JSON::ParserError', message: 'Invalid JSON' }

        expect(response).to have_http_status(:bad_request)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(400)
        expect(response_body['error']['code']).to eq('invalid_json')
        expect(response_body['error']['message']).to eq('Invalid JSON format')
        expect(response_body['error']['timestamp']).to be_present
      end
    end

    context 'when Redis::BaseError error occurs' do
      it 'returns 503 status with service_unavailable code' do
        get :test_action, params: { error_type: 'Redis::BaseError', message: 'Redis connection failed' }

        expect(response).to have_http_status(:service_unavailable)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(503)
        expect(response_body['error']['code']).to eq('service_unavailable')
        expect(response_body['error']['message']).to eq('Service temporarily unavailable')
        expect(response_body['error']['timestamp']).to be_present
      end
    end

    context 'when Timeout::Error error occurs' do
      it 'returns 504 status with timeout code' do
        get :test_action, params: { error_type: 'Timeout::Error', message: 'Request timeout' }

        expect(response).to have_http_status(:gateway_timeout)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(504)
        expect(response_body['error']['code']).to eq('timeout')
        expect(response_body['error']['message']).to eq('Request timeout')
        expect(response_body['error']['timestamp']).to be_present
      end
    end

    context 'when StandardError error occurs' do
      it 'returns 500 status with internal_error code' do
        allow(Rails.logger).to receive(:error)

        get :test_action, params: { error_type: 'StandardError', message: 'Something went wrong' }

        expect(response).to have_http_status(:internal_server_error)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(500)
        expect(response_body['error']['code']).to eq('internal_error')
        expect(response_body['error']['message']).to eq('Internal server error')
        expect(response_body['error']['timestamp']).to be_present

        expect(Rails.logger).to have_received(:error).with('StandardError: Something went wrong')
      end
    end

    context 'when unknown error occurs' do
      it 'returns 500 status with internal_error code' do
        allow(Rails.logger).to receive(:error)

        get :test_action, params: { error_type: 'RuntimeError', message: 'Unknown error' }

        expect(response).to have_http_status(:internal_server_error)
        response_body = response.parsed_body

        expect(response_body['success']).to be false
        expect(response_body['status']).to eq(500)
        expect(response_body['error']['code']).to eq('internal_error')
        expect(response_body['error']['message']).to eq('Internal server error')
        expect(response_body['error']['timestamp']).to be_present
      end
    end
  end
end
