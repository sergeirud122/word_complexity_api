# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Word Complexity Score API',
        description: 'Asynchronous API for calculating complexity scores of words based on synonyms and antonyms from dictionary data',
        version: 'v1',
        contact: {
          name: 'API Support',
          email: 'support@example.com',
        },
      },
      paths: {},
      servers: [
        {
          url: 'http://127.0.0.1:3000',
          description: 'Development server',
        },
      ],
      components: {
        schemas: {
          JobResponse: {
            type: :object,
            properties: {
              job_id: {
                type: :string,
                pattern: '^[0-9a-f]{16}$',
                description: 'Unique identifier for the complexity calculation job',
              },
            },
            required: ['job_id'],
          },
          JobStatusPending: {
            type: :object,
            properties: {
              status: {
                type: :string,
                enum: ['pending'],
                description: 'Job is queued and waiting to be processed',
              },
            },
            required: ['status'],
          },
          JobStatusInProgress: {
            type: :object,
            properties: {
              status: {
                type: :string,
                enum: ['in_progress'],
                description: 'Job is currently being processed',
              },
            },
            required: ['status'],
          },
          JobStatusCompleted: {
            type: :object,
            properties: {
              status: {
                type: :string,
                enum: ['completed'],
                description: 'Job has completed successfully',
              },
              result: {
                type: :object,
                additionalProperties: { type: :number },
                description: 'Complexity scores for each word. Score = (synonyms + antonyms) / definitions',
                example: {
                  'happy' => 3.5,
                  'joyful' => 4.0,
                  'sad' => 2.8,
                  'angry' => 3.2,
                },
              },
            },
            required: %w[status result],
          },
          JobStatusFailed: {
            type: :object,
            properties: {
              status: {
                type: :string,
                enum: ['failed'],
                description: 'Job processing failed',
              },
              error: {
                type: :string,
                description: 'Error message describing what went wrong',
              },
            },
            required: %w[status error],
          },
          ErrorResponse: {
            type: :object,
            properties: {
              success: { type: :boolean, enum: [false] },
              status: { type: :integer },
              error: {
                type: :object,
                properties: {
                  code: { type: :string },
                  message: { type: :string },
                  timestamp: { type: :string, format: 'date-time' },
                  details: { type: :object },
                },
                required: %w[code message timestamp],
              },
            },
            required: %w[success status error],
          },
          WordsArray: {
            type: :array,
            items: {
              type: :string,
              minLength: 1,
              maxLength: 50,
              pattern: '^[a-zA-Z\'-]+$',
            },
            minItems: 1,
            maxItems: 100,
            description: 'Array of words to analyze for complexity',
            example: %w[happy joyful sad angry],
          },
        },
      },
    },
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
