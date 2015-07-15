module Houston
  module Slack
    class ResponseError < RuntimeError
      def initialize(response, message)
        super message
        additional_information[:response] = response
      end
    end
  end
end
