if Houston.server? || ENV["HOUSTON_SLACK"] == "start"
  Houston::Slack.connection.listen!
else
  puts "\e[94mSkipping Slack Listener since we're not running as a server\e[0m"
  Rails.logger.info "\e[94mSkipping Slack Listener since we're not running as a server\e[0m"
end
