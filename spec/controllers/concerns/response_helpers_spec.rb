# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponseHelpers do
  # Создаем тестовый контроллер с маршрутами
  controller(ActionController::Base) do
    include ResponseHelpers

    def test_render_error
      render json: { status: 'ok' }
    end

    def test_render_error_default
      render json: { status: 'ok' }
    end
  end

  # Добавляем маршруты для тестового контроллера
  before do
    routes.draw do
      get 'test_render_error' => 'anonymous#test_render_error'
      get 'test_render_error_default' => 'anonymous#test_render_error_default'
    end
  end

  describe '#render_error' do
    context 'with all parameters provided' do
      it 'renders successful response' do
        get :test_render_error

        expect(response).to have_http_status(:ok)
        response_body = response.parsed_body
        expect(response_body['status']).to eq('ok')
      end
    end

    context 'with default parameters' do
      it 'renders successful response' do
        get :test_render_error_default

        expect(response).to have_http_status(:ok)
        response_body = response.parsed_body
        expect(response_body['status']).to eq('ok')
      end
    end
  end
end
