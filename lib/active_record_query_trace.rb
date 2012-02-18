require 'active_support/log_subscriber'

module ActiveRecordQueryTrace

  class << self
    attr_accessor :enabled
  end

  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber

      def initialize
        super
        ActiveRecordQueryTrace.enabled = false
      end

      def sql(event)
        if ActiveRecordQueryTrace.enabled
          debug("\e[1m\e[35m\e[1m\e[47mCalled from:\e[0m " + clean_trace(caller[2..-2]).join("\n "))
        end
      end

      def clean_trace(trace)
        Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.clean(trace) : trace
      end

      attach_to :active_record
    end
  end
end