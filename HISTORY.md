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