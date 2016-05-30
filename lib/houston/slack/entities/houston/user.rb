require "attentive/entity"

# https://get.slack.help/hc/en-us/articles/216360827-Changing-your-username

# Usernames can be up to 21 characters long. They can contain lowercase letters
# a to z (without accents), and numbers 0 to 9. We hope to make usernames more
# customizable in future!

Attentive::Entity.define "houston.user", "{{slack.user}}" do |match|
  User.find_by_slack_username match["slack.user"].username
end
