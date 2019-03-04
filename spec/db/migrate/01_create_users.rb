# frozen_string_literal: true

SUPERCLASS =
  if ActiveRecord.version < Gem::Version.new('5.0')
    ActiveRecord::Migration
  else
    version = "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
    ActiveRecord::Migration[version]
  end

class CreateUsers < SUPERCLASS
  def change
    create_table :users do |t|
      t.timestamps null: false
    end
  end
end
