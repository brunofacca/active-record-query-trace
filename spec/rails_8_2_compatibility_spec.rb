# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails 8.2 Compatibility' do
  it 'loads without error' do
    expect { ActiveRecordQueryTrace::CustomLogSubscriber }.not_to raise_error
  end

  it 'can trace SQL queries' do
    ActiveRecordQueryTrace.enabled = true
    ActiveRecordQueryTrace.level = :app

    log_output = StringIO.new
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = Logger.new(log_output)

    begin
      User.count
      logged_content = log_output.string

      expect(logged_content).to include('SELECT')
      expect(logged_content).to include('users')
    ensure
      ActiveRecord::Base.logger = old_logger
      ActiveRecordQueryTrace.enabled = false
    end
  end
end
