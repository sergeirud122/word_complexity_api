# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseForm, type: :form do
  # Создаем тестовый класс для тестирования BaseForm
  class TestForm < BaseForm
    attribute :name, :string
    attribute :email, :string
    attribute :age, :integer

    validates :name, presence: true
    validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
    validates :age, numericality: { greater_than: 0, less_than: 150 }
  end

  describe '#submit' do
    context 'with valid data' do
      let(:form) { TestForm.new(name: 'John Doe', email: 'john@example.com', age: 25) }

      it 'returns true when form is valid' do
        expect(form.submit).to be true
      end
    end

    context 'with invalid data' do
      let(:form) { TestForm.new(name: '', email: 'invalid-email', age: -5) }

      it 'returns false when form is invalid' do
        expect(form.submit).to be false
      end
    end
  end

  describe 'protected methods' do
    let(:form) { TestForm.new }

    describe '#valid_uuid?' do
      it 'validates correct UUID format' do
        expect(form.send(:valid_uuid?, '550e8400-e29b-41d4-a716-446655440000')).to be true
        expect(form.send(:valid_uuid?, '550E8400-E29B-41D4-A716-446655440000')).to be true
      end

      it 'rejects invalid UUID format' do
        expect(form.send(:valid_uuid?, 'invalid-uuid')).to be false
        expect(form.send(:valid_uuid?, '550e8400-e29b-41d4-a716-44665544000')).to be false # too short
        expect(form.send(:valid_uuid?, '550e8400-e29b-41d4-a716-4466554400000')).to be false # too long
        expect(form.send(:valid_uuid?, '')).to be false
        expect(form.send(:valid_uuid?, nil)).to be false
      end
    end

    describe '#valid_word_format?' do
      it 'validates correct word format' do
        expect(form.send(:valid_word_format?, 'hello')).to be true
        expect(form.send(:valid_word_format?, "world's")).to be true
        expect(form.send(:valid_word_format?, 'co-operation')).to be true
        expect(form.send(:valid_word_format?, 'multiple words')).to be true
      end

      it 'rejects invalid word format' do
        expect(form.send(:valid_word_format?, '')).to be false
        expect(form.send(:valid_word_format?, nil)).to be false
        expect(form.send(:valid_word_format?, 'a' * 51)).to be false # too long
        expect(form.send(:valid_word_format?, 'inv@lid')).to be false
        expect(form.send(:valid_word_format?, 'word123')).to be false
        expect(form.send(:valid_word_format?, 'word!')).to be false
      end
    end

    describe '#sanitize_string' do
      it 'sanitizes valid strings' do
        expect(form.send(:sanitize_string, '  hello world  ')).to eq('hello world')
        expect(form.send(:sanitize_string, 'test')).to eq('test')
      end

      it 'handles edge cases' do
        expect(form.send(:sanitize_string, '')).to be_nil
        expect(form.send(:sanitize_string, nil)).to be_nil
        expect(form.send(:sanitize_string, '   ')).to be_nil
      end

      it 'truncates long strings' do
        long_string = 'a' * 300
        result = form.send(:sanitize_string, long_string, max_length: 100)
        expect(result.length).to eq(100)
        expect(result).to end_with('...')
      end
    end
  end
end
