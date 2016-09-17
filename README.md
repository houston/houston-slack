# Houston::Slack

This module allows Houston to post messages on Slack and to listen (and respond) to conversations via [Slack's Real Time Messaging API](https://api.slack.com/rtm).

Communicating with Slack via its APIs is implemented by [slacks](https://github.com/houston/slacks).

Matching listeners to incoming messages is implemented by [attentive](https://github.com/houston/attentive).



## Installation

In your `Gemfile`, add:

    gem "houston-slack", github: "houston/houston-slack", branch: "master"

And in `config/main.rb`, add:

```ruby
use :slack do
  token ENV["HOUSTON_SLACK_TOKEN"]
end
```

And then execute:

    $ bundle



## Usage

### Configuration

To use Houston::Slack, you need to add add a new [Bot User Integration](https://api.slack.com/bot-users) to your Slack team. Slack will provide an API token for your user that starts with `xoxb-`. Copy the token into the `use :slack` block like this:

```ruby
use :slack do
  token "xoxb-0000000000-abcdefghijklmnopqrstuvwx"
end
```



### Sending messages

You can send messages from Houston with `Houston::Slack.send`.

`send` takes two arguments:

 - **message** — the message to be sent, a string
 - **options** — a hash of options including:
   - **:channel** — (required) the channel to send the message to (e.g. `@username` or `#general`)
   - **:attachments**, **:username**, **:as_user**, **:parse**, **:link_names**, **:unfurl_links**, **:unfurl_media**, **:icon_url**, **:icon_emoji** — (optional) are [defined by Slack](https://api.slack.com/methods/chat.postMessage) and passed through by Houston::Slack

###### Example

```ruby
Houston::Slack.send "Hi! I'm Baymax, your personal healthcare companion.",
  channel: "#general"
```



### Listening

```ruby
Houston::Conversations.config do
  listen_for("hurry up") { |e| e.reply "I am not fast" }
  listen_for("fist bump") { |e| e.reply ":fist:", "ba da lata lata la" }
end
```

Houston can also listen to any messages sent within the hearing of the Bot User. It does this by plugging those messages into Houston's Conversations system. To learn more about setting up—and responding to—listeners, see [Houston::Conversations's README](https://github.com/houston/houston-conversations#houstonconversations).



### Slash Commands

`Houston::Slack::Slash` can respond to [slash commands](https://api.slack.com/slash-commands) created for your team in Slack. A slash command sends Houston user inputed text and **must** receive a message in response.

When you create a slash command on Slack set the **URL** to `http://houstondomain.com/slack/command` and set the method to `POST`.

###### Example

This example responds to the slash command `/weather` where the user is expected to enter a zipcode.

```ruby
Houston::Slack.config do
  slash("weather") do |e|
    zipcode = e.text
    weather = WeatherAPI.get_weather(zipcode)
    message = "Today is #{weather.to_s}"
    e.respond! message
  end
end
```



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
