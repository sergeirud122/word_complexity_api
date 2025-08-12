# frozen_string_literal: true

class ApplicationController < ActionController::API
  include LocaleHelpers
  include ResponseHelpers
  include SimpleErrorHandling
end
