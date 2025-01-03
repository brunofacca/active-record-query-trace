## 1.8.3 (2025-01-03)

* Add support for Ruby 3.4

## 1.8.2 (2023-07-27)

* Fix Rubocop offenses.

* Remove older Ruby and Rails versions from the CI and add newer versions.

* Update dependencies.

## 1.8.1 (2023-07-23)

* Fix collisions with other gems in `Rails.backtrace_cleaner`

## 1.8

* Add support to Ruby 3.

* Drop support for Ruby 2.4.

* Small improvement to the README.

## 1.7

* Add ability to provide custom backtrace cleaner.

* Make it possible to use the gem without rails (see
[here](https://github.com/brunofacca/active-record-query-trace/issues/9#issuecomment-544443322)).

* Refactor tests to use a different gemfile for each Rails version.

* Fix compatibility with latest `master` branch of Rails.

* Bug fixes.

## 1.6.2 (2019-03-12)

* Improve backtrace cleaner silencers for `:app` level. When .level is set to
`:app`, only display files within `Rails.root`. When set to `:rails`, only
display files outside of `Rails.root`;

* Add mininum Ruby version to gemspec.

## 1.6.1 (2019-03-10)

* Minor fixes and improvements such as adding Rails 4.0.0 to the CI and adding
dependency versions in `gemspec`.

## 1.6 (2019-03-05)

* Fix a bug in the `.ignore_cached_queries` option (#30);

* Add `.query_type` option to display the trace only for DB read or write queries;

* Add `.suppress_logging_of_db_reads` option. When enabled, all DB read queries 
(SELECT) are suppressed from the log;

* Refactor in an attempt to make the code easier to read, test and maintain;

* Setup RSpec and SQLite 3 with in-memory DB for testing;

* Setup Rubocop and fix all offenses;

* Setup Travis CI to test the project with multiple Ruby and Rails versions;

* Drop support for Rails 3 and Ruby 2.2;

* Remove Gemfile.lock from the repository to prevent dependency issues;

* Improve and expand README;

* Other minor improvements.

## 1.5.4 (2016-10-12)

* Enable colorization of output log - thanks @ihinojal

## 1.5.2 (2015-11-12)

* Track queries from 'lib' or 'engines' folders. Thanks to @amalkov

* Updates to log formatting to make it look better. Thanks to @carsonreinke

## 1.5 (2015-09-23)

Merge pull request #13 from mtyeh411/fix_root_trace_filter

Fixed Rails 4.2 backtrace_cleaner root filter with sql-logging gem

Thank you @mtyeh411

## 1.4 (2015-03-05)

Support for ignoring `ActiveRecord` cached queries that show up in the log with a `CACHE` prefix.

```ruby
ActiveRecordQueryTrace.ignore_cached_queries = true
```

See this Pull-Request for additional notes on how these cached queries can also be skipped from the log file:

https://github.com/ruckus/active-record-query-trace/pull/10

Thank you to @tinynumbers for this contribution.

## < 1.3

Unavailable. Sorry, I was not keep tracking of history prior to `1.4`
