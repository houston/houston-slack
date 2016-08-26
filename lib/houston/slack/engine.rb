require "houston/slack/railtie"

module Houston
  module Slack
    class Engine < ::Rails::Engine
      isolate_namespace Houston::Slack

      # Precompile this modules assets
      initializer :assets do |config|
        Rails.application.config.assets.precompile += %w(
          houston/slack/application.js
          houston/slack/application.css )
      end

      # Include the Engine's migrations with the Application
      # http://pivotallabs.com/leave-your-migrations-in-your-rails-engines/
      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end

      initializer "houston.slack.start-listening" do
        Houston::Slack.instance_variable_set :@session,
          Houston::Slack::Session.new(Houston::Slack.connection)
      end

    end
  end
end
