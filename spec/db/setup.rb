# frozen_string_literal: true

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.timestamps null: false
  end
end

# Dummy model
class User < ActiveRecord::Base
end
