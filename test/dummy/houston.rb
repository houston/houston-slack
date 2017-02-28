# Load Houston
require "houston/application"

# Configure Houston
Houston.config do

  # Houston should load config/database.yml from this module
  # rather than from Houston Core.
  root Pathname.new File.expand_path("../../..",  __FILE__)

  # Give dummy values to these required fields.
  host "houston.test.com"
  secret_key_base "e15bb17b88c7ba34ec587b93fdb46f"
  mailer_sender "houston@test.com"

  # Mount this module on the dummy Houston application.
  use :slack do
    token "xoxb-0000000000-abcdefghijklmnopqrstuvwx"
  end

end
