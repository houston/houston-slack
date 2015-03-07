Rails.application.routes.draw do

  mount Slack::Engine => "/slack"
end
