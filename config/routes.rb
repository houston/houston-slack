Houston::Slack::Engine.routes.draw do

  scope "slack" do
    get "/", to: "slack#show"
    post "/connect", to: "slack#connect"
  end

end
