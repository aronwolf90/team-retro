# One shared password for the whole team. Set TEAM_PASSWORD in production.
Rails.application.config.x.team_password = ENV.fetch("TEAM_PASSWORD") do
  if Rails.env.production?
    raise "Set the TEAM_PASSWORD environment variable"
  else
    "retro"
  end
end
