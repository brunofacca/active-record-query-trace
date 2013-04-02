Logs the source of execution of all queries to the Rails log. Helpful to track down where queries are being executed in your application, for performance optimizations most likely.

Install
-------

`gem install active_record_query_trace`

Usage
-----

Enable it in an initializer:

```ruby
ActiveRecordQueryTrace.enabled = true

# Optional
ActiveRecordQueryTrace.level = :app (default)
ActiveRecordQueryTrace.level = :full (alternate ouput of full backtrace, useful for debugging gems)
```

Output
------

When enabled every query source will be logged like:

```
  IntuitAccount Load (1.2ms)  SELECT "intuit_accounts".* FROM "intuit_accounts" WHERE "intuit_accounts"."user_id" = 20 LIMIT 1
Called from: app/views/users/edit.html.haml:78:in `block in _app_views_users_edit_html_haml___1953197429694975654_70177901460360'
 app/views/users/edit.html.haml:16:in `_app_views_users_edit_html_haml___1953197429694975654_70177901460360'
```

Requirements
------------
Rails 3+

Copyright (c) 2011 Cody Caughlan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
