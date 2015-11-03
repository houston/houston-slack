module Houston::Slack
  class SlashCommand
    attr_reader :text

    def initialize(controller, params)
      @controller = controller
      @text = params.fetch :text
    end

    def respond!(message)
      raise Houston::Slack::AlreadyRespondedError if controller.performed?
      controller.render text: message
    end

  private
    attr_reader :controller

  end
end
