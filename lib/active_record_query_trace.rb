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
    attr_accessor :suppress_logging_of_db_reads
  end

  class CustomLogSubscriber < ActiveRecord::LogSubscriber # rubocop:disable Metrics/ClassLength
    def initialize
      super
      ActiveRecordQueryTrace.enabled = false
      ActiveRecordQueryTrace.level = :app
      ActiveRecordQueryTrace.lines = 5
      ActiveRecordQueryTrace.ignore_cached_queries = false
      ActiveRecordQueryTrace.colorize = false
      ActiveRecordQueryTrace.query_type = :all
      ActiveRecordQueryTrace.suppress_logging_of_db_reads = false
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

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # TODO: refactor and remove rubocop:disable comments.
    def display_backtrace?(payload)
      ActiveRecordQueryTrace.enabled \
        && !transaction_begin_or_commit_query?(payload) \
        && !schema_query?(payload) \
        && !(ActiveRecordQueryTrace.ignore_cached_queries && payload[:cached]) \
        && !(ActiveRecordQueryTrace.suppress_logging_of_db_reads && db_read_query?(payload)) \
        && display_backtrace_for_query_type?(payload)
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

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
      !payload[:sql] =~ /\ASELECT\s/i
    end

    def fully_formatted_trace
      cleaned_trace = clean_trace(original_trace)
      return if cleaned_trace.blank?
      stringified_trace = BACKTRACE_PREFIX + lines_to_display(cleaned_trace).join("\n" + INDENTATION)
      colorize_text(stringified_trace)
    end

    # Must be called after the backtrace cleaner.
    def lines_to_display(full_trace)
      ActiveRecordQueryTrace.lines.zero? ? full_trace : full_trace.first(ActiveRecordQueryTrace.lines)
    end

    def transaction_begin_or_commit_query?(payload)
      payload[:sql].match(/\A(begin transaction|commit transaction|BEGIN|COMMIT)\Z/)
    end

    def schema_query?(payload)
      payload[:name] == 'SCHEMA'
    end

    def clean_trace(full_trace)
      invalid_level_msg = 'Invalid ActiveRecordQueryTrace.level value ' \
              "#{ActiveRecordQueryTrace.level}. Should be :full, :rails, or :app."
      raise(invalid_level_msg) unless %i[full app rails].include?(ActiveRecordQueryTrace.level)

      trace = ActiveRecordQueryTrace.level == :full ? full_trace : Rails.backtrace_cleaner.clean(full_trace)
      # We cant use a Rails::BacktraceCleaner filter to display only the relative
      # path of application trace lines because it breaks the silencer that selects
      # the lines to display or hide based on whether they include `Rails.root`.
      trace.map { |line| line.gsub("#{Rails.root}/", '') }
    end

    # Rails by default silences all backtraces that *do not* match
    # Rails::BacktraceCleaner::APP_DIRS_PATTERN. In other words, the default
    # silencer filters out all framework backtrace lines, leaving only the
    # application lines.
    def setup_backtrace_cleaner
      setup_backtrace_cleaner_path
      return if ActiveRecordQueryTrace.level == :full

      remove_filters_and_silencers

      case ActiveRecordQueryTrace.level
      when :app
        Rails.backtrace_cleaner.add_silencer { |line| !line.match(rails_root_regexp) }
      when :rails
        Rails.backtrace_cleaner.add_silencer { |line| line.match(rails_root_regexp) }
      end
    end

    # Rails relies on backtrace cleaner to set the application root directory
    # filter. The problem is that the backtrace cleaner is initialized before
    # this gem. This ensures that the value of `root` used by the filter
    # is correct.
    def setup_backtrace_cleaner_path
      return unless Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
      Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
    end

    def remove_filters_and_silencers
      Rails.backtrace_cleaner.remove_filters!
      Rails.backtrace_cleaner.remove_silencers!
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

    # This cannot be set in a constant as Rails.root is not yet available when
    # this file is loaded.
    def rails_root_regexp
      %r{#{Regexp.escape(Rails.root.to_s)}(?!\/vendor)}
    end
  end
end

# The following code is used to suppress specific entries from the log. The
# "around alias" technique is used to allow `ActiveSupport::LogSubscriber#debug`
# to be overwritten while preserving the original version, which can still be
# called.
#
# I would prefer using Module#prepend here, but alias_method does not work if
# called from within a prepended module.
#
# Note that:
# - #debug is used to log queries but also other things, do not mess it up.
# - Some queries include both SELECT and a write operation such as INSERT,
# UPDATE or DELETE. That means that checking for the presence of SELECT is not
# enough to ensure it is not a write query.
#
# TODO: move to a separate file.
ActiveSupport::LogSubscriber.class_eval do
  alias_method :original_debug, :debug

  def debug(*args, &block)
    return if ActiveRecordQueryTrace.suppress_logging_of_db_reads \
      && args.first !~ /(INSERT|UPDATE|DELETE|#{ActiveRecordQueryTrace::BACKTRACE_PREFIX})/
    original_debug(*args, &block)
  end
end
