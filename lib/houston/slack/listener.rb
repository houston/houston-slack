module Houston::Slack
  class Listener
    attr_reader :matcher
    attr_accessor :conversation
    
    def initialize(matcher, callback)
      @matcher = matcher.freeze
      @callback = callback
    end
    
    def match(message)
      matcher.match(message)
    end
    
    def stop_listening!
      Houston::Slack.config.listeners.delete self
      self
    end
    
    def call(e)
      Thread.new do
        begin
          @callback.call(e)
        rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
          Houston.report_exception $!, parameters: {channel: e.channel, message: e.message, sender: e.sender}
          e.reply "An error occurred when I was trying to answer you"
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end
    
  end
end
