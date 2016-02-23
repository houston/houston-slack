Houston::Slack::Engine.routes.draw do

  scope "slack" do
    get "/", to: "slack#show"
    post "/connect", to: "slack#connect"
    get "/command", to: "slack#ssl_verify"
    post "/command", to: "slack#command"
  end

end
