module Houston
  module Slack
    class User
      attr_reader :id, :email, :first_name, :last_name
      
      def initialize(attributes={})
        profile = attributes["profile"]
        @id = attributes["id"]
        @email = profile["email"]
        @first_name = profile["first_name"]
        @last_name = profile["last_name"]
      end
      
      def name
        "#{first_name} #{last_name}"
      end
      
      def to_s
        "<#{id}|#{name}>"
      end
      
    end
  end
end
