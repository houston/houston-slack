module Houston::Slack
  class Configuration
    
    def initialize
      config = Houston.config.module(:slack).config
      instance_eval(&config) if config
    end
    
    # Define configuration DSL here
    
    def token(*args)
      @token = args.first if args.any?
      @token
    end
    
  end
end
