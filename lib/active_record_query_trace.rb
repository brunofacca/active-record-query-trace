# encoding: UTF-8
require 'active_support/log_subscriber'

module ActiveRecordQueryTrace

  class << self
    attr_accessor :enabled
    attr_accessor :level
    attr_accessor :lines
    attr_accessor :ignore_cached_queries
    attr_accessor :colorize
  end

  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber

      def initialize
        super
        ActiveRecordQueryTrace.enabled = false
        ActiveRecordQueryTrace.level = :app
        ActiveRecordQueryTrace.lines = 5
        ActiveRecordQueryTrace.ignore_cached_queries = false
        ActiveRecordQueryTrace.colorize = false

        if ActiveRecordQueryTrace.level != :app
          # Rails by default silences all backtraces that match Rails::BacktraceCleaner::APP_DIRS_PATTERN
          Rails.backtrace_cleaner.remove_silencers!
        end
      end

      def sql(event)
        if ActiveRecordQueryTrace.enabled
          index = begin
            if ActiveRecordQueryTrace.lines == 0
              0..-1
            else
              0..(ActiveRecordQueryTrace.lines - 1)
            end
          end

          payload = event.payload
          return if payload[:name] == 'SCHEMA'
          return if ActiveRecordQueryTrace.ignore_cached_queries && payload[:name] == 'CACHE'

          cleaned_trace = clean_trace(caller)[index].join("\n     from ")
          debug("  Query Trace > " + colorize_text(cleaned_trace)) unless cleaned_trace.blank?
        end
      end

      # Allow query to be colorized in the terminal
      def colorize_text(text)
        return text unless ActiveRecordQueryTrace.colorize
        # Try to convert the choosen color from string to integer or try
        # to use the colorize as the color code
        colors = {
          true => "38",       "blue" => "34",        "light red" => "1;31",
          "black" => "30",    "purple" => "35",      "light green" => "1;32",
          "red" => "31",      "cyan" => "36",        "yellow" => "1;33",
          "green" => "32",    "gray" => "37",        "light blue" => "1;34",
          "brown" => "33",    "dark gray" => "1;30", "light purple" => "1;35",
          "white" => "1;37",  "light cyan" => "1;36"
        }
        color_code = colors[ActiveRecordQueryTrace.colorize] ||
          ActiveRecordQueryTrace.colorize.to_s
        unless /\d+(;\d+){0,1}/.match(color_code)
          raise "Invalid color. Use one of #{ colors.keys } or a valid color code"
        end
        "\e[#{ color_code }m#{ text }\e[0m"
      end

      def clean_trace(trace)
        # Rails relies on backtrace cleaner to set the application root directory filter
        # the problem is that the backtrace cleaner is initialized before the application
        # this ensures that the value of `root` used by the filter is set to the application root
        if Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
          Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
        end

        case ActiveRecordQueryTrace.level
        when :full
          trace
        when :rails
          Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.clean(trace) : trace
        when :app
          Rails.backtrace_cleaner.remove_silencers!
          Rails.backtrace_cleaner.add_silencer { |line| not line =~ /^(app|lib|engines)\// }
          Rails.backtrace_cleaner.clean(trace)
        else
          raise "Invalid ActiveRecordQueryTrace.level value '#{ActiveRecordQueryTrace.level}' - should be :full, :rails, or :app"
        end
      end

      attach_to :active_record

    end
  end
end
