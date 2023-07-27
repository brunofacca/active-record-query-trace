# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'active_record'
require 'active_record_query_trace'
require 'db/setup'
require 'debug'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module Rails
  module_function

  # Fake Rails root path for specs (since we don't have an actual Rails app in this gem's test environment)
  def root
    '/projects/my_rails_project'
  end

  def backtrace_cleaner
    @backtrace_cleaner ||= begin
      # Relies on Active Support, so we have to lazy load to postpone definition until Active Support has been loaded
      require 'rails/backtrace_cleaner'
      Rails::BacktraceCleaner.new
    end
  end
end
