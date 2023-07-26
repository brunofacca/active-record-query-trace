# frozen_string_literal: true

require 'active_record/log_subscriber'
require_relative 'active_record_query_trace/version'

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
    attr_accessor :enabled, :lines, :ignore_cached_queries, :colorize, :query_type, :suppress_logging_of_db_reads
    attr_writer :default_cleaner
    attr_reader :backtrace_cleaner, :level

    def backtrace_cleaner=(cleaner)
      @backtrace_cleaner =
        if cleaner.is_a?(Proc)
          cleaner
        else
          proc { |trace| cleaner.clean(trace) }
        end
    end

    # When changing the level we need to reset the backtrace cleaner used
    def level=(level)
      @level = level
      @default_cleaner = nil
    end

    def default_cleaner
      @default_cleaner ||= setup_backtrace_cleaner
    end

    # The following code creates a brand new BacktraceCleaner just for the use of this Gem
    # avoiding the dealing with Rails.backtrace_cleaner
    def setup_backtrace_cleaner
      cleaner = Rails::BacktraceCleaner.new
      remove_filters_and_silencers cleaner
      cleaner.instance_variable_set :@root, Rails.root.to_s if cleaner.instance_variable_get(:@root) == '/'
      case ActiveRecordQueryTrace.level
      when :app
        cleaner.add_silencer { |line| line !~ rails_root_regexp }
      when :rails
        cleaner.add_silencer { |line| line =~ rails_root_regexp }
      end
      cleaner
    end

    def remove_filters_and_silencers(cleaner)
      cleaner.remove_filters!
      cleaner.remove_silencers!
    end

    # This cannot be set in a constant as Rails.root is not yet available when
    # this file is loaded.
    def rails_root_regexp
      @rails_root_regexp ||= %r{#{Regexp.escape(Rails.root.to_s)}(?!/vendor)}
    end
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
      trace = fully_formatted_trace # Memoize
      debug(trace) if trace.present?
    end

    delegate :default_cleaner, to: ActiveRecordQueryTrace

    attach_to :active_record

    private

    def cached_query?(payload)
      return false unless ActiveRecordQueryTrace.ignore_cached_queries
      payload[:cached] || payload[:name] == 'CACHE'
    end

    # TODO: refactor and remove rubocop:disable comments.
    def display_backtrace?(payload)
      ActiveRecordQueryTrace.enabled \
        && !transaction_begin_or_commit_query?(payload) \
        && !schema_query?(payload) \
        && !cached_query?(payload) \
        && !(ActiveRecordQueryTrace.suppress_logging_of_db_reads && db_read_query?(payload)) \
        && display_backtrace_for_query_type?(payload)
    end

    def display_backtrace_for_query_type?(payload)
      case ActiveRecordQueryTrace.query_type
      when :all then true
      when :read then db_read_query?(payload)
      when :write then !db_read_query?(payload)
      else
        raise 'Invalid ActiveRecordQueryTrace.query_type value ' \
              "#{ActiveRecordQueryTrace.level}. Should be :all, :read, or :write."
      end
    end

    def db_read_query?(payload)
      payload[:sql] !~ /INSERT|UPDATE|DELETE/
    end

    def fully_formatted_trace
      cleaned_trace = clean_trace(original_trace)
      return if cleaned_trace.blank?
      stringified_trace = BACKTRACE_PREFIX + lines_to_display(cleaned_trace).join("\n#{INDENTATION}")
      colorize_text(stringified_trace)
    end

    # Must be called after the backtrace cleaner.
    def lines_to_display(full_trace)
      ActiveRecordQueryTrace.lines.zero? ? full_trace : full_trace.first(ActiveRecordQueryTrace.lines)
    end

    def transaction_begin_or_commit_query?(payload)
      payload[:sql] =~ /\Abegin transaction|commit transaction|BEGIN|COMMIT\Z/
    end

    def schema_query?(payload)
      payload[:name] == 'SCHEMA'
    end

    # rubocop:disable Metrics/MethodLength
    def clean_trace(full_trace)
      case ActiveRecordQueryTrace.level
      when :full
        trace = full_trace
      when :app, :rails
        trace = default_cleaner.clean(full_trace)
      when :custom
        unless ActiveRecordQueryTrace.backtrace_cleaner
          raise 'Configure your backtrace cleaner first via ActiveRecordQueryTrace.backtrace_cleaner = MyCleaner'
        end
        trace = ActiveRecordQueryTrace.backtrace_cleaner.call(full_trace)
      else
        raise 'Invalid ActiveRecordQueryTrace.level value ' \
              "#{ActiveRecordQueryTrace.level}. Should be :full, :rails, or :app."
      end

      # We cant use a Rails::BacktraceCleaner filter to display only the relative
      # path of application trace lines because it breaks the silencer that selects
      # the lines to display or hide based on whether they include `Rails.root`.
      trace.map { |line| line.sub(rails_root_prefix, '') }
    end
    # rubocop:enable Metrics/MethodLength

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
      return @color_code if @color_code && @configured_color == ActiveRecordQueryTrace.colorize

      @configured_color = ActiveRecordQueryTrace.colorize

      # Backward compatibility for string color names with space as word separator.
      @color_code =
        case ActiveRecordQueryTrace.colorize
        when Symbol, true then COLORS[ActiveRecordQueryTrace.colorize]
        when String then COLORS[ActiveRecordQueryTrace.colorize.tr("\s", '_').to_sym]
        end
    end

    def validate_color_code(color_code)
      valid_color_code?(color_code) || raise(
        'ActiveRecordQueryTrace.colorize was set to an invalid ' \
        "color. Use one of #{COLORS.keys} or a valid color code."
      )
    end

    def valid_color_code?(color_code)
      /\A\d+(?:;\d+)?\Z/ =~ color_code
    end

    def rails_root_prefix
      @rails_root_prefix ||= "#{Rails.root}/"
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
      && args.first !~ /INSERT|UPDATE|DELETE|#{ActiveRecordQueryTrace::BACKTRACE_PREFIX}/o
    original_debug(*args, &block)
  end
end
