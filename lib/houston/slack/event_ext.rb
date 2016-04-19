require "slacks/event"

module Houston
  module Slack
    module EventExt

      def user
        return @user if defined?(@user)
        @user = sender && ::User.find_by_slack_username(sender.username)
      end

    end
  end
end

Slacks::Event.send :include, Houston::Slack::EventExt
