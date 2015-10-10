module Houston
  module Slack
    class User
      attr_reader :id, :username, :email, :first_name, :last_name

      def initialize(attributes={})
        profile = attributes["profile"]
        @id = attributes["id"]
        @username = attributes["name"]
        @email = profile["email"]
        @first_name = profile["first_name"]
        @last_name = profile["last_name"]
      end

      def name
        "#{first_name} #{last_name}"
      end

      def inspect
        "<Houston::Slack::User id=\"#{id}\" name=\"#{name}\">"
      end

      def to_s
        "@#{username}"
      end

    end
  end
end
