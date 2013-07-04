require 'active_support/log_subscriber'

module ActiveRecordQueryTrace

  class << self
    attr_accessor :enabled
    attr_accessor :level
    attr_accessor :lines
  end

  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber

      def initialize
        super
        ActiveRecordQueryTrace.enabled = false
        ActiveRecordQueryTrace.level = :app
        ActiveRecordQueryTrace.lines = 5
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

          debug(color('Called from: ', MAGENTA, true) + clean_trace(caller)[index].join("\n "))
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
        end
      end

      attach_to :active_record
    end
  end
end
