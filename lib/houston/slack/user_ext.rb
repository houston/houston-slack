require "active_support/concern"

module Houston
  module Slack
    module UserExt
      extend ActiveSupport::Concern

      module ClassMethods
        def find_by_slack_username(username)
          username = username.username if username.is_a? Slacks::User
          username = username.gsub(/^@/, "")

          find_by_prop "slack.username", username do |username|

            # Look up the email address of the Slack user and see if we can
            # identify the Houston user by the Slack user's email address.
            user = Houston::Slack.connection.users.detect { |user| user["name"] == username }
            user = find_by_email_address user["profile"]["email"] if user

          end
        end
      end

      def slack_username
        username = get_prop "slack.username" do

          # Look for a Slack user that has one of this Houston user's email addresses.
          user = Houston::Slack.connection.users.detect { |user| email_addresses.member?(user["profile"]["email"]) }
          user && user["name"]

        end
        "@" + username
      end
      alias :slack_channel :slack_username

      def set_slack_username!(username)
        update_column :view_options, view_options.merge(
          "slack_username" => username.gsub(/^@/, ""))
      end

    end
  end
end
