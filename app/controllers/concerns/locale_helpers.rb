# frozen_string_literal: true

module LocaleHelpers
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  def set_locale
    requested_locale = extract_locale_from_params || extract_locale_from_header
    I18n.locale = requested_locale if requested_locale
  end

  def current_locale
    I18n.locale
  end

  private

  def extract_locale_from_params
    locale_param = params[:locale] || request.headers['X-Locale']
    return nil unless locale_param

    locale_sym = locale_param.to_sym
    return locale_sym if I18n.available_locales.include?(locale_sym)

    nil
  end

  def extract_locale_from_header
    accept_language = request.headers['Accept-Language']
    return I18n.default_locale unless accept_language

    # Простой парсинг первого языка из заголовка
    first_locale = accept_language.split(',').first&.split('-')&.first&.to_sym
    return first_locale if first_locale && I18n.available_locales.include?(first_locale)

    I18n.default_locale
  end
end
