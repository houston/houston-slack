module Houston::Slack
  class Configuration
    attr_reader :responders
    
    def initialize
      @responders = []
      config = Houston.config.module(:slack).config
      instance_eval(&config) if config
    end
    
    # Define configuration DSL here
    
    def token(*args)
      @token = args.first if args.any?
      @token
    end
    
    def respond_to(matcher, &block)
      event = "slack:message:#{matcher}"
      @responders.push(matcher: matcher, event: event, mention: true)
      Houston.observer.on(event, &block)
      event
    end
    
    def overhear(matcher, &block)
      event = "slack:message:#{matcher}"
      @responders.push(matcher: matcher, event: event, mention: false)
      Houston.observer.on(event, &block)
      event
    end
    
  end
end
