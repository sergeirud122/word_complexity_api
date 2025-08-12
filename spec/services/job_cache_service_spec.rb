# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobCacheService, type: :service do
  let(:batch_key) { 'batch:abc123def456' }
  let(:job_id) { 'abc123def456' }

  before do
    allow(Rails.cache).to receive(:read)
    allow(Rails.cache).to receive(:write)
    allow(Rails.cache).to receive(:exist?)
    allow(Rails.cache).to receive(:delete)
  end

  describe '.result_exists?' do
    context 'when result exists' do
      it 'returns true when result key exists' do
        allow(Rails.cache).to receive(:exist?).with("job_result:#{job_id}").and_return(true)

        result = described_class.result_exists?(batch_key)

        expect(result).to be true
      end
    end

    context 'when result does not exist' do
      it 'returns false when result key does not exist' do
        allow(Rails.cache).to receive(:exist?).with("job_result:#{job_id}").and_return(false)

        result = described_class.result_exists?(batch_key)

        expect(result).to be false
      end
    end
  end

  describe '.get_job_status' do
    context 'when result exists (completed)' do
      it 'returns completed status with results' do
        results = { 'hello' => 0.75, 'world' => 0.25 }
        allow(Rails.cache).to receive(:read).with("job_result:#{job_id}").and_return(results)

        result = described_class.get_job_status(batch_key)

        expect(result).to eq({ status: 'completed', result: results })
      end
    end

    context 'when job is pending' do
      it 'returns pending status' do
        allow(Rails.cache).to receive(:read).with("job_result:#{job_id}").and_return(nil)
        allow(Rails.cache).to receive(:read).with("job_status:#{job_id}").and_return('pending')

        result = described_class.get_job_status(batch_key)

        expect(result).to eq({ status: 'pending' })
      end
    end

    context 'when job failed' do
      it 'returns failed status' do
        allow(Rails.cache).to receive(:read).with("job_result:#{job_id}").and_return(nil)
        allow(Rails.cache).to receive(:read).with("job_status:#{job_id}").and_return('failed')

        result = described_class.get_job_status(batch_key)

        expect(result).to eq({ status: 'failed' })
      end
    end

    context 'when job not found' do
      it 'returns nil when no status exists' do
        allow(Rails.cache).to receive(:read).with("job_result:#{job_id}").and_return(nil)
        allow(Rails.cache).to receive(:read).with("job_status:#{job_id}").and_return(nil)

        result = described_class.get_job_status(batch_key)

        expect(result).to be_nil
      end
    end
  end

  describe '.mark_as_pending' do
    it 'writes pending status to correct key' do
      described_class.mark_as_pending(batch_key)

      expect(Rails.cache).to have_received(:write).with(
        "job_status:#{job_id}",
        'pending',
        expires_in: 6.hours,
      )
    end

    it 'handles different batch keys' do
      different_key = 'batch:xyz789abc123'
      described_class.mark_as_pending(different_key)

      expect(Rails.cache).to have_received(:write).with(
        'job_status:xyz789abc123',
        'pending',
        expires_in: 6.hours,
      )
    end
  end

  describe '.mark_as_failed' do
    it 'writes failed status to status key' do
      described_class.mark_as_failed(batch_key)

      expect(Rails.cache).to have_received(:write).with(
        "job_status:#{job_id}",
        'failed',
        expires_in: 6.hours,
      )
    end
  end

  describe '.save_results' do
    let(:results) { { 'happy' => 0.75, 'sad' => 0.25 } }

    it 'saves results and deletes status' do
      described_class.save_results(batch_key, results)

      expect(Rails.cache).to have_received(:write).with(
        "job_result:#{job_id}",
        results,
        expires_in: 6.hours,
      )
      expect(Rails.cache).to have_received(:delete).with("job_status:#{job_id}")
    end
  end

  describe '.get_results' do
    let(:results) { { 'hello' => 0.75, 'world' => 0.25 } }

    it 'reads results from cache' do
      allow(Rails.cache).to receive(:read).with("job_result:#{job_id}").and_return(results)

      result = described_class.get_results(batch_key)

      expect(result).to eq(results)
    end
  end
end
