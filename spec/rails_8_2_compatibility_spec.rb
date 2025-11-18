# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails 8.2 Compatibility' do
  describe 'LogSubscriber inheritance' do
    it 'loads without error' do
      # This test will fail on Rails edge because attach_to doesn't exist
      expect { ActiveRecordQueryTrace::CustomLogSubscriber }.not_to raise_error
    end

    it 'inherits from the correct parent class' do
      parent_class = ActiveRecordQueryTrace::CustomLogSubscriber.superclass

      if defined?(ActiveSupport::EventReporter::LogSubscriber)
        # Rails 8.2+ should inherit from EventReporter::LogSubscriber
        expect(parent_class).to eq(ActiveSupport::EventReporter::LogSubscriber)
      else
        # Rails < 8.2 inherits from ActiveRecord::LogSubscriber
        expect(parent_class).to eq(ActiveRecord::LogSubscriber)
      end
    end

    it 'has namespace set for Rails 8.2+' do
      if defined?(ActiveSupport::EventReporter::LogSubscriber)
        expect(ActiveRecordQueryTrace::CustomLogSubscriber.namespace).to eq('active_record')
      else
        # Namespace is not used in older Rails
        skip 'Namespace only applies to Rails 8.2+'
      end
    end
  end

  describe 'Event subscription' do
    it 'is subscribed to ActiveRecord events' do
      if defined?(ActiveSupport::EventReporter)
        # Rails 8.2+ uses event_reporter.subscribe
        subscribers = ActiveSupport.event_reporter.instance_variable_get(:@subscribers)
        expect(subscribers).to include(an_instance_of(ActiveRecordQueryTrace::CustomLogSubscriber))
      else
        # Rails < 8.2 uses Notifications
        listeners = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record')
        expect(listeners).not_to be_empty
      end
    end

    it 'can handle SQL events' do
      # Enable query tracing
      ActiveRecordQueryTrace.enabled = true
      ActiveRecordQueryTrace.level = :app

      # Capture log output
      log_output = StringIO.new
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Logger.new(log_output)

      begin
        # Trigger a SQL query
        User.count

        # Check that the query was logged
        logged_content = log_output.string
        expect(logged_content).to include('SELECT')
        expect(logged_content).to include('users')
      ensure
        # Restore logger and disable tracing
        ActiveRecord::Base.logger = old_logger
        ActiveRecordQueryTrace.enabled = false
      end
    end
  end

  describe 'Event payload handling' do
    it 'can access payload from event' do
      subscriber = ActiveRecordQueryTrace::CustomLogSubscriber.new

      # Create a mock event that works with both Rails versions
      if defined?(ActiveSupport::EventReporter)
        # Rails 8.2+ passes events as hashes
        event = {
          name: 'sql.active_record',
          payload: {
            name: 'User Load',
            sql: 'SELECT * FROM users',
            cached: false
          },
          duration_ms: 1.5
        }
      else
        # Rails < 8.2 passes event objects
        event = ActiveSupport::Notifications::Event.new(
          'sql.active_record',
          Time.now,
          Time.now + 0.0015,
          SecureRandom.hex,
          {
            name: 'User Load',
            sql: 'SELECT * FROM users',
            cached: false
          }
        )
      end

      # This will fail on Rails edge if we don't handle the event structure difference
      expect { subscriber.sql(event) }.not_to raise_error
    end
  end

  describe 'Log level configuration' do
    it 'has sql method configured with debug log level' do
      if defined?(ActiveSupport::EventReporter::LogSubscriber)
        # Rails 8.2+ uses event_log_level
        expect(ActiveRecordQueryTrace::CustomLogSubscriber.log_levels['sql']).to eq(:debug)
      else
        # Rails < 8.2 uses subscribe_log_level
        # The method stores it differently but should still be :debug
        skip 'Log level checking differs between Rails versions'
      end
    end
  end

  describe 'Backward compatibility' do
    it 'works on the current Rails version' do
      # This is a smoke test - if the gem loads and can trace queries, it works
      ActiveRecordQueryTrace.enabled = true
      ActiveRecordQueryTrace.level = :app

      log_output = StringIO.new
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Logger.new(log_output)

      begin
        User.count
        logged_content = log_output.string

        # Should have both the SQL query and trace information
        expect(logged_content).to include('SELECT')
        expect(logged_content).to include('COUNT')
      ensure
        ActiveRecord::Base.logger = old_logger
        ActiveRecordQueryTrace.enabled = false
      end
    end
  end
end
