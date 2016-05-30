require "attentive/entity"

# https://get.slack.help/hc/en-us/articles/216360827-Changing-your-username

# Usernames can be up to 21 characters long. They can contain lowercase letters
# a to z (without accents), and numbers 0 to 9. We hope to make usernames more
# customizable in future!

Attentive::Entity.define "slack.user", %q{(?<username>@[a-z0-9]+)} do |match|
  begin
    Houston::Slack.connection.find_user_by_nickname match["username"]
  rescue ArgumentError
    nomatch!
  end
end
