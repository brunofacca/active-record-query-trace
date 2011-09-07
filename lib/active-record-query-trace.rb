module QueryTrace
  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber
      
      def initialize
        super
      end
      
      def sql(event)
        #debug("#{event.payload[:name]} (#{event.duration}) #{event.payload[:sql]}")
        debug("\e[1m\e[35m\e[1m\e[47mCalled from:\e[0m " + clean_trace(caller[2..-2]).join("\n "))
      end
      
      def clean_trace(trace)
        Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.clean(trace) : trace
      end
      
      attach_to :active_record
    end
  end
end