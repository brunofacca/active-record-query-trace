# frozen_string_literal: true

MIGRATIONS_PATH = File.expand_path('migrate', __dir__)

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Dummy model
class User < ActiveRecord::Base
end

ActiveRecord::Migration.verbose = false

if defined?(ActiveRecord::MigrationContext)
  ActiveRecord::MigrationContext.new(MIGRATIONS_PATH).up
else
  ActiveRecord::Migrator.migrate(MIGRATIONS_PATH, nil)
end
