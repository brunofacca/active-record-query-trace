require 'active_support/log_subscriber'

module ActiveRecordQueryTrace

  class << self
    attr_accessor :enabled
    attr_accessor :level
    attr_accessor :lines
    attr_accessor :ignore_cached_queries
  end

  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber

      def initialize
        super
        ActiveRecordQueryTrace.enabled = false
        ActiveRecordQueryTrace.level = :app
        ActiveRecordQueryTrace.lines = 5
        ActiveRecordQueryTrace.ignore_cached_queries = false
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

          debug(color("Called from: \n  ", MAGENTA, true) + clean_trace(caller)[index].join("\n  "))
        end
      end

      def clean_trace(trace)
        case ActiveRecordQueryTrace.level
        when :full
          trace
        when :rails
          Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.clean(trace) : trace
        when :app
          Rails.backtrace_cleaner.add_silencer { |line| not line =~ /^app/ }
          Rails.backtrace_cleaner.clean(trace)
        else
          raise "Invalid ActiveRecordQueryTrace.level value '#{ActiveRecordQueryTrace.level}' - should be :full, :rails, or :app"
        end
      end

      attach_to :active_record
    end
  end
end
