# frozen_string_literal: true

require 'active_record/log_subscriber'
require 'active_support/core_ext/hash/indifferent_access'

module ActiveRecordQueryTrace
  INDENTATION = ' ' * 6
  BACKTRACE_PREFIX = "Query Trace:\n#{INDENTATION}"
  COLORS = {
    true => '38',
    blue: '34',
    light_red: '1;31',
    black: '30',
    purple: '35',
    light_green: '1;32',
    red: '31',
    cyan: '36',
    yellow: '1;33',
    green: '32',
    gray: '37',
    light_blue: '1;34',
    brown: '33',
    dark_gray: '1;30',
    light_purple: '1;35',
    white: '1;37',
    light_cyan: '1;36'
  }.with_indifferent_access.freeze

  class << self
    attr_accessor :enabled
    attr_accessor :level
    attr_accessor :lines
    attr_accessor :ignore_cached_queries
    attr_accessor :colorize

    def logger
      ::ActiveRecord::LogSubscriber.logger
    end

    def logger=(new_logger)
      ::ActiveRecord::LogSubscriber.logger = new_logger
    end
  end

  class CustomLogSubscriber < ActiveRecord::LogSubscriber
    def initialize
      super
      ActiveRecordQueryTrace.enabled = false
      ActiveRecordQueryTrace.level = :app
      ActiveRecordQueryTrace.lines = 5
      ActiveRecordQueryTrace.ignore_cached_queries = false
      ActiveRecordQueryTrace.colorize = false
    end

    # TODO: refactor this method and re-enable the following cops.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def sql(event)
      return unless ActiveRecordQueryTrace.enabled

      index = begin
        if ActiveRecordQueryTrace.lines.zero?
          0..-1
        else
          0..(ActiveRecordQueryTrace.lines - 1)
        end
      end

      payload = event.payload
      return if payload[:name] == 'SCHEMA' \
        || payload[:sql] == 'begin transaction' \
        || payload[:sql] == 'commit transaction'
      return if ActiveRecordQueryTrace.ignore_cached_queries && payload[:cached]

      cleaned_trace = clean_trace(original_trace)[index].join("\n" + INDENTATION)
      debug(colorize_text(BACKTRACE_PREFIX + cleaned_trace)) unless cleaned_trace.blank?
    end

    def clean_trace(trace)
      # Rails relies on backtrace cleaner to set the application root directory
      # filter the problem is that the backtrace cleaner is initialized before
      # the application this ensures that the value of `root` used by the filter
      # is set to the application root
      if Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
        Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
      end

      case ActiveRecordQueryTrace.level
      when :full
        trace
      when :rails
        # Rails by default silences all backtraces that *do not* match
        # Rails::BacktraceCleaner::APP_DIRS_PATTERN. In other words, the default
        # silencer filters out all framework backtrace frames, leaving only the
        # application frames.
        Rails.backtrace_cleaner.remove_silencers!
        Rails.backtrace_cleaner.add_silencer { |line| line =~ %r{^(app|lib|engines)/} }
        Rails.backtrace_cleaner.clean(trace)
      when :app
        Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.clean(trace) : trace
      else
        raise "Invalid ActiveRecordQueryTrace.level value '#{ActiveRecordQueryTrace.level}' " \
              '- should be :full, :rails, or :app'
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # Allow query to be colorized in the terminal
    def colorize_text(text)
      return text unless ActiveRecordQueryTrace.colorize
      "\e[#{color_code}m#{text}\e[0m"
    end

    attach_to :active_record

    private

    # Wrapper used for testing purposes.
    def original_trace
      caller
    end

    def color_code
      color_code = COLORS[ActiveRecordQueryTrace.colorize]

      error_msg = 'ActiveRecordQueryTrace.colorize was set to an invalid ' \
           "color. Use one of #{COLORS.keys} or a valid color code."

      raise error_msg unless valid_color_code?(color_code)
      color_code
    end

    def valid_color_code?(color_code)
      /\A\d+(;\d+)?\Z/.match(color_code)
    end
  end
end
