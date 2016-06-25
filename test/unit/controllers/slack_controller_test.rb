require "test_helper"

class Houston::Slack::SlackControllerTest < ActionController::TestCase



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
      post :command, {use_route: :slack}.merge(slash_command_payload)
      assert_response :success
    end

    should "invoke the registered Slash command" do
      post :command, {use_route: :slack}.merge(slash_command_payload)
      assert_equal 1, @calls
    end

    should "look up the channel where the command was triggered" do
      mock(Houston::Slack.connection).find_channel("C0D1UMW7Q")
      post :command, {use_route: :slack}.merge(slash_command_payload)
    end

    should "look up the user that issued the command" do
      mock(Houston::Slack.connection).find_user("U0D1QH53N")
      post :command, {use_route: :slack}.merge(slash_command_payload)
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

end
