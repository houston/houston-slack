require "slacks/user"

module Houston
  module Slack
    module SenderExt

      def user
        return @user if defined?(@user)
        @user = ::User.find_by_slack_username(username)
      end

    end
  end
end

Slacks::User.send :include, Houston::Slack::SenderExt
