# Houston::Slack

This module allows Houston to post messages on Slack and to listen (and respond) to conversations via [Slack's Real Time Messaging API](https://api.slack.com/rtm)


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

Houston can also listen to any messages sent within the hearing of the Bot User. There are two methods for listening: `listen_for` and `overhear`. Both take a regular expression and yield a `Houston::Slack::Event` to a block when that regular expression matches. The difference is that `listen_for` is only triggered if the chat is directed to Houston (i.e. Houston is mentioned or the chat is sent as a direct message to Houston) whereas `overhear` is triggered if the message is said in Houston's hearing.

#### Houston::Slack::Event

`Houston::Slack::Event` responds to:

 - `#message` — which returns the entire chat which was matched
 - `#sender` — returns the use who sent the message (an instance of `Houston::Slack::User`)
 - `#user` — returns the `::User` who sent the message (it looks up Houston `User` by the sender's email address. If it doesn't find a corresponding user, it will return `nil`)
 - `#channel` — returns the channel, private group, or direct message where the message was sent (an instance of `Houston::Slack::Channel`)
 - `#match` — returns the `MatchData` when the regular expression was matched to the message
 - `#matched?(key)` — indicates whether a named capture group was matched in the message
 - `#stop_listening!` — will clean up the listener that matched this message.
 - `#reply(*messages)` — will send one or more messages from Houston on the channel where this event occurred
 - `#start_conversation!` — will create a new `Houston::Slack::Converation` on this channel between Houston and this messages's sender

###### Example

This simple example listens for certain commands and then replies when Houston hears them:

```ruby
Houston::Slack.config do
  listen_for(/hurry up/i) { |e| e.reply "I am not fast" }
  listen_for(/fist bump/i) { |e| e.reply ":fist:", "ba da lata lata la" }
end
```

#### Houston::Slack::Conversation

When Houston is in a conversation with a person, it can listen for its correspondent to say specific words or phrases with `listen_for` — but without requiring its correspondent to mention Houston's name every time.

`Houston::Slack::Conversation` responds to:

 - `#reply(*messages)`, `#say(*messages)` — will send one or more messages from Houston on the channel where this conversation is taking place
 - `#listen_for(matcher, &block)` — adds a new listener tied to this conversation
 - `#ask(question, expect: <regular-expression>, &block)` — asks a question, then creates a listener for the anticipated responses. Upon hearing a response, it stops listening for that response and yields `Houston::Slack:Event` with the correspondent's response to Houston's question
 - `#end!` — ends the conversation and cleans up all listeners tied to it

###### Example

This example overhears a trigger word, "ouch!", and then enters a conversation with the injured person long enough to ask how they would rate their pain and make a reply.

```ruby
Houston::Slack.config do
  overhear(/\bouch\b/i) do |e|
    conversation = e.start_conversation!
    conversation.ask(
        "On a scale of 1 to 10, how would you rate your pain?",
        expect: /^(?<pain>[1-9]|10)$/) do |e|

      case e.match[:pain].to_i
      when 0..5; converation.say "I am sorry to hear that"
      when 6..10; converation.say "It is OK to cry"
      end

      conversation.end!
    end
  end
end
```



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
