require "thread_safe"

module Houston::Slack
  class Conversation

    def initialize(channel, sender)
      @channel = channel
      @sender = sender
      @listeners = ThreadSafe::Array.new
    end

    def listen_for(matcher, &block)
      Houston::Slack.config.listen_for(matcher, &block).tap do |listener|
        listener.conversation = self
        listeners.push(listener)
      end
    end

    def includes?(e)
      e.channel.id == channel.id && e.sender.id == sender.id
    end

    def reply(*messages)
      channel.reply(*messages)
    end
    alias :say :reply

    def ask(question, expect: nil)
      listen_for(expect) do |e|
        e.stop_listening!
        yield e
      end

      reply question
    end

    def end!
      listeners.each(&:stop_listening!)
    end

  private
    attr_reader :channel, :sender, :listeners

  end
end
