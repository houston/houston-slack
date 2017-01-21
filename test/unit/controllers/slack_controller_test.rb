require "test_helper"

class Houston::Slack::SlackControllerTest < ActionController::TestCase

  def setup
    @routes = Houston::Slack::Engine.routes
  end



  context "When Slack posts a slash command event, it" do
    setup do
      @calls = 0
      Houston::Slack.config.slash("test") { @calls += 1 }
      stub(Houston::Slack.connection).find_channel("C0D1UMW7Q").returns({})
      stub(Houston::Slack.connection).find_user("U0D1QH53N").returns({})
    end

    teardown do
      Houston::Slack.config.instance_variable_get(:@slash_commands).clear
    end

    should "respond with success" do
      post :command, params: slash_command_payload
      assert_response :success
    end

    should "invoke the registered Slash command" do
      post :command, params: slash_command_payload
      assert_equal 1, @calls
    end

    should "look up the channel where the command was triggered" do
      mock(Houston::Slack.connection).find_channel("C0D1UMW7Q")
      post :command, params: slash_command_payload
    end

    should "look up the user that issued the command" do
      mock(Houston::Slack.connection).find_user("U0D1QH53N")
      post :command, params: slash_command_payload
    end
  end



  context "When Slack posts a message button event, it" do
    setup do
      @calls = 0
      Houston::Slack.config.action("test:merge") { @calls += 1 }
      stub(Houston::Slack.connection).find_channel("C0D1UMW7Q").returns({})
      stub(Houston::Slack.connection).find_user("U0D1QH53N").returns({})
    end

    teardown do
      Houston::Slack.config.instance_variable_get(:@actions).clear
    end

    should "respond with success" do
      post :message, params: message_button_payload
      assert_response :success
    end

    should "invoke the registered action" do
      post :message, params: message_button_payload
      assert_equal 1, @calls
    end

    should "look up the channel where the command was triggered" do
      mock(Houston::Slack.connection).find_channel("C0D1UMW7Q")
      post :message, params: message_button_payload
    end

    should "look up the user that issued the command" do
      mock(Houston::Slack.connection).find_user("U0D1QH53N")
      post :message, params: message_button_payload
    end
  end



private

  def slash_command_payload(params={})
    { "token"=>"this token is sent by Slack so you can verify the command",
      "team_id"=>"T0D1SUB2S",
      "team_domain"=>"houston-sandbox",
      "channel_id"=>"C0D1UMW7Q",
      "channel_name"=>"alerts",
      "user_id"=>"U0D1QH53N",
      "user_name"=>"boblail",
      "command"=>"/test",
      "text"=>"",
      "response_url"=>"https://hooks.slack.com/commands/T0D1SUB2S/something"
    }.merge(params)
  end

  def message_button_payload(params={})
    { payload: <<-JSON }
    { "actions": [{ "name": "merge", "value": "merge" }],
      "callback_id": "test",
      "team": { "id": "T0D1SUB2S", "domain": "houston-sandbox" },
      "channel": { "id": "C0D1UMW7Q", "name": "alertrs" },
      "user": { "id": "U0D1QH53N", "name": "boblail" },
      "action_ts": "1484873847.542306",
      "message_ts": "1484873252.000005",
      "attachment_id": "1",
      "token": "this token is sent by Slack so you can verify the command",
      "original_message": {
        "type": "message",
        "user": "U3TV84KH9",
        "text": "hi",
        "bot_id": "B3U4EA7GD",
        "attachments": [{
          "callback_id": "test",
          "fallback": "A certain pull request is ready to merge",
          "text": "A certain pull request is ready to merge",
          "id": 1,
          "color": "3AA3E3",
          "actions": [{
            "id": "1",
            "name": "merge",
            "text": "Merge",
            "type": "button",
            "value": "merge"
          }]
        }],
        "ts": "1484873252.000005"
      },
      "response_url": "https://hooks.slack.com/actions/T0D1SUB2S/129387369393/oAybdq3DbNlj8cvEJEK7AOmc" }
    JSON
  end

end
