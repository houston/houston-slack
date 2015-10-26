# Houston::Slack

This module allows Houston to post messages on Slack and to listen (and respond) to conversations via [Slack's Real Time Messaging API](https://api.slack.com/rtm)


## Installation

In your `Gemfile`, add:

    gem "houston-slack"

And in `config/main.rb`, add:

```ruby
use :slack do
  # TODO: specify configuration options for Houston::Slack here
end
```

And then execute:

    $ bundle


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
