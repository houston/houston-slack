module Houston
  module Slack
    class MigrationInProgress < RuntimeError
      def initialize
        super "Team is being migrated between servers. Try the request again in a few seconds."
      end
    end

    class ResponseError < RuntimeError
      def initialize(response, message)
        super message
        additional_information[:response] = response
      end
    end
  end
end
