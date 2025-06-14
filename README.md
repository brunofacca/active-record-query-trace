Displays a backtrace for each query in Rails' development console and log.
Allows you to track down where queries are executed in your application.
Useful for performance optimizations and for finding where to start when making
changes to a large application.

When enabled, every query will be logged like:

```
D, [2019-03-03T19:50:41.061115 #25560] DEBUG -- : User Load (0.1ms)  SELECT "users".* FROM "users"
D, [2019-03-03T19:50:41.062492 #25560] DEBUG -- : Query Trace:
      app/models/concerns/is_active.rb:11:in `active?'
      app/models/user.rb:67:in `active?'
      app/decorators/concerns/status_methods.rb:42:in `colored_status'
      app/views/shared/companies/_user.html.slim:28:in `block in _app_views_users_html_slim___2427456029761612502_70304705622200'
      app/views/shared/companies/_user.html.slim:27:in `_app_views_users_html_slim___2427456029761612502_70304705622200'
```

## Requirements
- Ruby >= 2.7;
- Rails 6.0, 6.1, or 7.

## Usage

1. Add the following to your Gemfile:
   ```ruby
   group :development do
     gem 'active_record_query_trace'
   end
   ```

2. Create an initializer such as `config/initializers/active_record_query_trace.rb`
to enable the gem. If you want to customize how the gem behaves, you can add any
combination of the following [options](#options) to the initializer as well.

    ```ruby
    if Rails.env.development?
      ActiveRecordQueryTrace.enabled = true
      # Optional: other gem config options go here
    end
    ```

3. Restart the Rails development server.

## Options

#### Backtrace level
There are three levels of debug.

- `:app` - includes only application trace lines (files in the `Rails.root` directory);
- `:rails` - includes all trace lines except the ones from the application (all files except those in `Rails.root`).
- `:full` - full backtrace (includes all files), useful for debugging gems.

```ruby
ActiveRecordQueryTrace.level = :app # default
```

If you need more control you can provide a custom backtrace cleaner using the `:custom` level. For example:

```ruby
ActiveRecordQueryTrace.level = :custom
require "rails/backtrace_cleaner"
ActiveRecordQueryTrace.backtrace_cleaner = Rails::BacktraceCleaner.new.tap do |bc|
  bc.remove_filters!
  bc.remove_silencers!
  bc.add_silencer { |line| line =~ /\b(active_record_query_trace|active_support|active_record|another_gem)\b/ }
end
```

It's not necessary to create an instance of `Rails::BacktraceCleaner`, you can use any object responding to `#clean` or even
a lambda/proc:

```ruby
ActiveRecordQueryTrace.backtrace_cleaner = ->(trace) {
  trace.reject { |line| line =~ /\b(active_record_query_trace|active_support|active_record|another_gem)\b/ }
}
```

#### Display the trace only for read or write queries
You can choose to display the backtrace only for DB reads, writes or both.

- `:all` - display backtrace for all queries;
- `:read` - display backtrace only for DB read operations (SELECT);
- `:write` - display the backtrace only for DB write operations (INSERT, UPDATE, DELETE).

```ruby
ActiveRecordQueryTrace.query_type = :all # default
```

#### Suppress DB read queries
If set to `true`, this option will suppress all log lines generated by DB
read (SELECT) operations, leaving only the lines generated by DB write queries
(INSERT, UPDATE, DELETE). **Beware, the entire log line is suppressed, not only
the backtrace.** Useful to reduce noise in the logs (e.g., N+1 queries) when you
only care about queries that write to the DB.

```ruby
ActiveRecordQueryTrace.suppress_logging_of_db_reads = false # default
```

#### Ignore cached queries
By default, a backtrace will be logged for every query, even cached queries that
do not actually hit the database. You might find it useful not to print the backtrace
for cached queries:

```ruby
ActiveRecordQueryTrace.ignore_cached_queries = true # Default is false.
```

#### Limit the number of lines in the backtrace
If you are working with a large app, you may wish to limit the number of lines
displayed for each query.  If you set `level` to `:full`, you might want to set
`lines` to `0` so you can see the entire trace.

```ruby
ActiveRecordQueryTrace.lines = 10 # Default is 5. Setting to 0 includes entire trace.
```

#### Colorize the backtrace
To colorize the output:

```ruby
ActiveRecordQueryTrace.colorize = false           # No colorization (default)
ActiveRecordQueryTrace.colorize = :light_purple   # Colorize in specific color
```

Valid colors are: `:black`, `:red`, `:green`, `:brown`, `:blue`, `:purple`, `:cyan`,
`:gray`, `:dark_gray`, `:light_red`, `:light_green`, `:yellow`, `:light_blue`,
`:light_purple`, `:light_cyan`, `:white`.

## Authors

- **Cody Caughlan** - Original author.
- **Bruno Facca** - Current maintainer. [LinkedIn](https://www.linkedin.com/in/brunofacca/)

## Contributing

#### Bug reports

Please use the issue tracker to report any bugs.

#### Test environment

This gem uses RSpec for testing. You can run the test suite by executing the
`rspec` command. It has a decent test coverage and the test suite takes less than
a second to run as it uses an in-memory SQLite DB.

#### Developing

1. Create an issue and describe your idea
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Implement your changes;
5. Run the test suite (`rspec`)
6. Commit your changes (`git commit -m 'Add some feature'`)
7. Publish the branch (`git push origin my-new-feature`)
8. Create a Pull Request

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
