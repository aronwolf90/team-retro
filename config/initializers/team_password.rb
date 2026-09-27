# One shared password for the whole team. Set TEAM_PASSWORD in production.
Rails.application.config.x.team_password = ENV.fetch("TEAM_PASSWORD") do
  if Rails.env.production? && !ENV["SECRET_KEY_BASE_DUMMY"]
    raise "Set the TEAM_PASSWORD environment variable"
  else
    "retro"
  end
end
