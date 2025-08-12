# frozen_string_literal: true

class ComplexityScoresController < ApplicationController
  def show
    job_id = params[:id]

    return render_invalid_job_id(job_id) unless valid_job_id?(job_id)

    batch_key = "batch:#{job_id}"
    job_status = JobCacheService.get_job_status(batch_key)

    return render_job_not_found(job_id) if job_status.nil?

    render_job_status(job_status)
  end

  def create
    form = WordsForm.new(raw_request_body: request.body.read)
    return render_form_errors(form) unless form.submit

    words = form.processed_words
    batch_key = BatchKeyGenerator.generate(words)
    job_id = BatchKeyGenerator.extract_job_id(batch_key)

    unless JobCacheService.result_exists?(batch_key)
      JobCacheService.mark_as_pending(batch_key)
      ComplexityScoreJob.perform_later(words, batch_key)
    end

    render json: { job_id: job_id }, status: :accepted
  end

  private

  def render_job_status(job_status)
    case job_status[:status]
    when 'pending'
      render json: { status: 'pending' }, status: :ok
    when 'completed'
      render json: { status: 'completed', result: job_status[:result] }, status: :ok
    when 'failed'
      render json: { status: 'failed' }, status: :unprocessable_entity
    end
  end

  def render_invalid_job_id(job_id)
    render_error('Invalid job ID format', status: 400, job_id: job_id)
  end

  def render_job_not_found(job_id)
    render_error('Job not found', status: 404, job_id: job_id)
  end

  def render_form_errors(form)
    errors = form.formatted_errors
    render_error('Validation failed', status: 422, errors: errors[:summary])
  end

  def valid_job_id?(job_id)
    job_id.present? && job_id.to_s.match?(/\A[0-9a-f]{16}\z/i)
  end
end
