Houston::Slack::Engine.routes.draw do

  scope "slack" do
    get "/", to: "slack#show"
    post "/connect", to: "slack#connect"
    post "/command", to: "slack#command"
  end

end
