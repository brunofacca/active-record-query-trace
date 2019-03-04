# frozen_string_literal: true

require 'active_record/log_subscriber'

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
  }.freeze

  class << self
    attr_accessor :enabled
    attr_accessor :level
    attr_accessor :lines
    attr_accessor :ignore_cached_queries
    attr_accessor :colorize
    attr_accessor :query_type
  end

  class CustomLogSubscriber < ActiveRecord::LogSubscriber
    def initialize
      super
      ActiveRecordQueryTrace.enabled = false
      ActiveRecordQueryTrace.level = :app
      ActiveRecordQueryTrace.lines = 5
      ActiveRecordQueryTrace.ignore_cached_queries = false
      ActiveRecordQueryTrace.colorize = false
      ActiveRecordQueryTrace.query_type = :all
    end

    def sql(event)
      payload = event.payload
      return unless display_backtrace?(payload)

      setup_backtrace_cleaner

      trace = fully_formatted_trace # Memoize
      debug(trace) unless trace.blank?
    end

    attach_to :active_record

    private

    def display_backtrace?(payload)
      ActiveRecordQueryTrace.enabled \
        && !transaction_begin_or_commit_query?(payload) \
        && !schema_query?(payload) \
        && !(ActiveRecordQueryTrace.ignore_cached_queries && payload[:cached]) \
        && display_backtrace_for_query_type?(payload)
    end

    def display_backtrace_for_query_type?(payload)
      invalid_type_msg = 'Invalid ActiveRecordQueryTrace.query_type value ' \
        "#{ActiveRecordQueryTrace.level}. Should be :all, :read, or :write."

      case ActiveRecordQueryTrace.query_type
      when :all then true
      when :read then db_read_query?(payload)
      when :write then !db_read_query?(payload)
      else raise(invalid_type_msg)
      end
    end

    def db_read_query?(payload)
      payload[:name]&.match(/ Load\Z/)
    end

    def fully_formatted_trace
      cleaned_trace = clean_trace(lines_to_display)
      return if cleaned_trace.blank?
      stringified_trace = BACKTRACE_PREFIX + cleaned_trace.join("\n" + INDENTATION)
      colorize_text(stringified_trace)
    end

    def lines_to_display
      ActiveRecordQueryTrace.lines.zero? ? original_trace : original_trace.first(ActiveRecordQueryTrace.lines)
    end

    def transaction_begin_or_commit_query?(payload)
      payload[:sql] == 'begin transaction' || payload[:sql] == 'commit transaction'
    end

    def schema_query?(payload)
      payload[:name] == 'SCHEMA'
    end

    def clean_trace(full_trace)
      invalid_level_msg = 'Invalid ActiveRecordQueryTrace.level value ' \
              "#{ActiveRecordQueryTrace.level}. Should be :full, :rails, or :app."
      raise(invalid_level_msg) unless %i[full app rails].include?(ActiveRecordQueryTrace.level)

      ActiveRecordQueryTrace.level == :full ? full_trace : Rails.backtrace_cleaner.clean(full_trace)
    end

    # Rails by default silences all backtraces that *do not* match
    # Rails::BacktraceCleaner::APP_DIRS_PATTERN. In other words, the default
    # silencer filters out all framework backtrace lines, leaving only the
    # application lines.
    def setup_backtrace_cleaner
      setup_backtrace_cleaner_path
      return unless ActiveRecordQueryTrace.level == :rails
      Rails.backtrace_cleaner.remove_silencers!
      Rails.backtrace_cleaner.add_silencer { |line| line.match(%r{^(app|lib|engines)/}) }
    end

    # Rails relies on backtrace cleaner to set the application root directory
    # filter. The problem is that the backtrace cleaner is initialized before
    # this gem. This ensures that the value of `root` used by the filter
    # is correct.
    def setup_backtrace_cleaner_path
      return unless Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
      Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
    end

    # Allow query to be colorized in the terminal
    def colorize_text(text)
      return text unless ActiveRecordQueryTrace.colorize
      "\e[#{color_code}m#{text}\e[0m"
    end

    # Wrapper used for testing purposes.
    def original_trace
      caller
    end

    def color_code
      # Backward compatibility for string color names with space as word separator.
      color_code =
        case ActiveRecordQueryTrace.colorize
        when Symbol then COLORS[ActiveRecordQueryTrace.colorize]
        when String then COLORS[ActiveRecordQueryTrace.colorize.tr("\s", '_').to_sym]
        end

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
