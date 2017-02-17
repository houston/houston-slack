require "houston/slack/slash_command"
require "houston/slack/action"

module Houston::Slack
  class SlackController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:command, :message]

    def show
      @connection = Houston::Slack.connection
    end

    def connect
      Houston::Slack.connection.listen! unless Houston::Slack.connection.listening?
      redirect_to action: :show
    end

    # Before submitting a command to your server, Slack will occasionally send
    # your command URLs a simple GET request to verify the certificate. These
    # requests will include a parameter ssl_check set to 1. Mostly, you may
    # ignore these requests, but please do respond with a HTTP 200 OK.
    # https://api.slack.com/slash-commands#best_practices
    def ssl_verify
      head :ok
    end


    def command
      command_name = params.fetch(:command).gsub(/^\//, "")
      command = Houston::Slack.config.slash_commands[command_name]
      unless command
        render plain: "A slash command named '#{command_name}' is not defined", status: 404
        return
      end

      if Houston::Slack.connection.listening? && Houston::Slack.connection.team.id != params["team_id"]
        render plain: "Houston is connected to the team #{Houston::Slack.connection.team.domain}, but this slash command is registered to the team #{params["team_domain"]}. Houston can't answer it.", status: 200
        return
      end

      text = params.fetch :text
      response_url = params.fetch :response_url
      sender = Houston::Slack.connection.find_user(params.fetch(:user_id))

      begin
        channel = Houston::Slack.connection.find_channel(params.fetch(:channel_id))
      rescue ArgumentError
        # Happens when using a slash command in a DM or channel that Houston is
        # not privy to. But as long as we're using only `respond!` or
        # `delayed_respond!`, we don't really need the channel.
        channel = Slacks::GuestChannel.new(params)
      end

      e = Houston::Slack::SlashCommand.new(
        message: text,
        channel: channel,
        sender: sender,
        response_url: response_url,
        controller: self)

      command.call e
      head :ok unless performed?
    end


    def message
      payload = MultiJson.load(params.fetch(:payload))
      action = payload.fetch("actions")[0]

      callback_id = payload.fetch("callback_id")
      action_name = action.fetch("name")
      action_value = action.fetch("value")
      # token = payload.fetch("token") # TODO: verify token
      response_url = payload.fetch("response_url")
      attachment_index = payload.fetch("attachment_id").to_i - 1

      action_name = [callback_id, action_name].join(":")
      action = Houston::Slack.config.actions[action_name]
      unless action
        render plain: "An action named '#{action_name}' is not defined", status: 404
        return
      end

      if Houston::Slack.connection.listening? && Houston::Slack.connection.team.id != payload.fetch("team")["id"]
        render plain: "Houston is connected to the team #{Houston::Slack.connection.team.domain}, but this slash command is registered to the team #{payload.fetch("team")["domain"]}. Houston can't answer it.", status: 200
        return
      end

      sender = Houston::Slack.connection.find_user(payload.fetch("user")["id"])

      begin
        channel = Houston::Slack.connection.find_channel(payload.fetch("channel")["id"])
      rescue ArgumentError
        # Happens when using a slash command in a DM or channel that Houston is
        # not privy to. But as long as we're using only `respond!` or
        # `delayed_respond!`, we don't really need the channel.
        channel = Slacks::GuestChannel.new(params)
      end

      e = Houston::Slack::Action.new(
        channel: channel,
        sender: sender,
        response_url: response_url,
        controller: self,

        name: action_name,
        value: action_value,
        ts: payload.fetch("action_ts"),
        original_message: payload.fetch("original_message"),
        attachment_index: attachment_index)

      action.call e
      head :ok unless performed?
    end

  end
end
