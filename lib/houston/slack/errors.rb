module Houston
  module Slack
    class AlreadyRespondedError < RuntimeError
      def initialize(message=nil)
        super message || "You have already replied to this Slash Command; you can only reply once"
      end
    end
  end
end
