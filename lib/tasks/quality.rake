# frozen_string_literal: true

namespace :quality do
  desc 'Run RuboCop with auto-correction'
  task rubocop: :environment do
    puts '🔍 Running RuboCop...'
    system('bundle exec rubocop -A')
  end

  desc 'Run RuboCop without auto-correction'
  task rubocop_check: :environment do
    puts '🔍 Checking RuboCop violations...'
    system('bundle exec rubocop')
  end

  desc 'Run Reek for code smell detection'
  task reek: :environment do
    puts '👃 Running Reek for code smells...'
    system('bundle exec reek')
  end

  desc 'Run Rails Best Practices'
  task rails_best_practices: :environment do
    puts '📋 Running Rails Best Practices...'
    system('bundle exec rails_best_practices .')
  end

  desc 'Run Brakeman security scanner'
  task brakeman: :environment do
    puts '🔒 Running Brakeman security scan...'
    system('bundle exec brakeman -A -q')
  end

  desc 'Run Bundler Audit for gem vulnerabilities'
  task bundle_audit: :environment do
    puts '💎 Checking gem vulnerabilities...'
    system('bundle exec bundle-audit update')
    system('bundle exec bundle-audit check')
  end

  desc 'Run Flog for code complexity analysis'
  task flog: :environment do
    puts '📊 Running Flog complexity analysis...'
    system('bundle exec flog app/ lib/')
  end

  desc 'Run Flay for code duplication detection'
  task flay: :environment do
    puts '🔄 Running Flay duplication detection...'
    system('bundle exec flay app/ lib/')
  end

  desc 'Generate YARD documentation'
  task yard: :environment do
    puts '📚 Generating YARD documentation...'
    system('bundle exec yard doc')
  end

  desc 'Run all linters and quality checks'
  task all: %i[
    rubocop_check
    reek
    rails_best_practices
    brakeman
    bundle_audit
    flog
    flay
  ] do
    puts '✅ All quality checks completed!'
  end

  desc 'Fix all auto-fixable issues'
  task fix: %i[
    rubocop
    bundle_audit
  ] do
    puts '🔧 Auto-fix completed!'
  end

  desc 'Generate quality reports'
  task reports: %i[
    yard
    flog
    flay
  ] do
    puts '📊 Quality reports generated!'
  end

  desc 'CI quality checks (no auto-fix)'
  task ci: %i[
    rubocop_check
    reek
    brakeman
    bundle_audit
  ] do
    puts '🚀 CI quality checks passed!'
  end
end

# Default quality task
desc 'Run basic quality checks'
task quality: 'quality:all'
