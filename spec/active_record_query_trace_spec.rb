# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecordQueryTrace do
  it 'has a version number' do
    expect(ActiveRecordQueryTrace::VERSION).not_to be_nil
  end
end
