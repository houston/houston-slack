Houston::Slack::Engine.routes.draw do

  get "/", to: "slack#show"
  post "/connect", to: "slack#connect"

end
