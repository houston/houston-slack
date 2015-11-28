require "active_support/concern"

module Houston
  module Slack
    module UserExt
      extend ActiveSupport::Concern

      module ClassMethods
        def find_by_slack_username(username)
          username = username.gsub(/^@/, "")

          # If we can already identify the user who has the given username, return them
          user = ::User.where(["view_options->'slack_username' = ?", username]).first
          return user if user

          # Look up the email address of the Slack user and see if we can
          # identify the Houston user by the Slack user's email address.
          user = Houston::Slack.connection.users.detect { |user| user["name"] == username }
          user = find_by_email_address user["profile"]["email"] if user
          return nil unless user

          # If we have identified the user, store their username so that
          # we can skip the email-lookup step in the future.
          user.set_slack_username! username
          user
        end
      end

      def slack_username
        # If we've previously identified this user as a Slack user,
        # make sure that their username is still valid. If so, return it.
        username = view_options["slack_username"]
        username = "@" + username if username
        return username if Houston::Slack.connection.user_exists?(username)

        # Look for a Slack user that has one of this Houston user's
        # email addresses.
        user = Houston::Slack.connection.users.detect { |user|
          email_addresses.member?(user["profile"]["email"]) }
        return nil unless user

        # If we have identified the user, store their username so that
        # we can skip the email-lookup step in the future.
        username = "@" + user["name"]
        set_slack_username! username
        username
      end
      alias :slack_channel :slack_username

      def set_slack_username!(username)
        update_column :view_options, view_options.merge(
          "slack_username" => username.gsub(/^@/, ""))
      end

    end
  end
end
