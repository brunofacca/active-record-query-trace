Displays a backtrace for each query in Rails' development console and log. 
Allows you to track down where and when queries are executed in your application.
Useful for performance optimizations and for finding where to start when making
changes to a big application.

When enabled every query will be logged like:

```
D, [2019-03-03T19:50:41.061115 #25560] DEBUG -- : User Load (0.1ms)  SELECT "users".* FROM "users"
D, [2019-03-03T19:50:41.062492 #25560] DEBUG -- : Query Trace:
      /media/ArquivosBruno/git_repositories/active-record-query-trace/lib/active_record_query_trace.rb:75:in `sql'
      /home/bruno/.rvm/gems/ruby-2.5.3/gems/activesupport-5.2.2/lib/active_support/subscriber.rb:101:in `finish'
      /home/bruno/.rvm/gems/ruby-2.5.3/gems/activesupport-5.2.2/lib/active_support/log_subscriber.rb:84:in `finish'
      /home/bruno/.rvm/gems/ruby-2.5.3/gems/activesupport-5.2.2/lib/active_support/notifications/fanout.rb:104:in `finish'
      /home/bruno/.rvm/gems/ruby-2.5.3/gems/activesupport-5.2.2/lib/active_support/notifications/fanout.rb:48:in `block in finish'
```

## Requirements
- Ruby 2.4, 2.5 or 2.6;
- Rails/ActiveRecord 4.2, 5.2, or 6 (can be used with or without Rails).

## Usage

1. Install the latest stable release:
   
   A. *When using Rails:* add the following to your Gemfile, then restart the server:                      
   ```ruby
   gem 'active_record_query_trace'
   ``` 
 
   B. *When using ActiveRecord without Rails:* install manually:
   ```ruby
   gem install active_record_query_trace
   ``` 

2. Create an initializer within `config/initializers/` to enable the gem.
If you want to customize how the gem behaves, you can add any combination of the
following [options](#options) to the initializer as well.
 
    ```ruby
    ActiveRecordQueryTrace.enabled = true
    ```

## Options

#### Backtrace level
There are three levels of debug.

1. app - includes only files in your app/, lib/, and engines/ directories.
2. rails - includes files in your app as well as rails.
3. full - full backtrace, useful for debugging gems.

```ruby
ActiveRecordQueryTrace.level = :app # default
```

#### Ignore cached queries
By default, a backtrace will be logged for every query, even cached queries that 
do not actually hit the database. You might find it useful not to print the backtrace
for cached queries:

```ruby
ActiveRecordQueryTrace.ignore_cached_queries = true # Default is false.
```

#### Limit the number of lines in the backtrace
Additionally, if you are working with a large app, you may wish to limit the number 
of lines displayed for each query.

```ruby
ActiveRecordQueryTrace.lines = 10 # Default is 5. Setting to 0 includes entire trace.
```

#### Colorize the backtrace
If you want the output can be colorized with a string of the color or a code. 
Valid colors are: `:black`, `:red`, `:green`, `:brown`, `:blue`, `:purple`, `:cyan`, 
`:gray`, `:dark_gray`, `:light_red`, `:light_green`, `:yellow`, `:light_blue`, 
`:light_purple`, `:light_cyan`, `:white`.

```ruby
ActiveRecordQueryTrace.colorize = false           # No colorization (default)
ActiveRecordQueryTrace.colorize = :light_purple   # Colorize in specific color
ActiveRecordQueryTrace.colorize = true            # Colorize in default color
```

## Authors

- **Cody Caughlan** - Original author.
- **Bruno Facca** - Current maintainer. [LinkedIn](https://www.linkedin.com/in/brunofacca/)

## Contributing

#### Bug reports

Please use the issue tracker to report any bugs.

#### Test environment

This gem uses RSpec for testing. You can run the test suite by executing the
`rspec` command. It has decent test coverage and the test suite taks less than
a second to run due to using an in-memory SQLite DB.

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

