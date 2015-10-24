require "houston/slack/user_ext"

module Houston
  module Slack
    class Railtie < ::Rails::Railtie

      # The block you pass to this method will run for every request in
      # development mode, but only once in production.
      config.to_prepare do
        ::User.send(:include, Houston::Slack::UserExt)
      end

    end
  end
end
