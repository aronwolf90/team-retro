# Team Retro

[![CI](https://github.com/aronwolf90/team-retro/actions/workflows/ci.yml/badge.svg)](https://github.com/aronwolf90/team-retro/actions/workflows/ci.yml)

> **Note:** This is a hobby project to experiment with vibe coding. The whole app was built by
> describing what I wanted to Claude Code and iterating on the result. Expect rough edges.

A small, self-hosted clone of the default [EasyRetro](https://easyretro.io) board for **one team**.
Built with Rails 8, Hotwire (Turbo + Stimulus) and SQLite on top of the stock `rails new`
skeleton (Kamal, Thruster, RuboCop, Brakeman, GitHub Actions CI). No accounts: everybody shares
one team password and picks a display name.

## Features

- **Login with one team password** (`TEAM_PASSWORD`, defaults to `retro` in development).
- **Name modal** pops up when the session has no name yet; click your name in the header to change it.
- **Dashboard** of all boards with card counts, create / delete boards.
- **Board**: *How is everyone?* · *From last retro* · *Went Well* · *To Improve* · *Action Items* (columns are fixed).
- **Follow-up**: a new board starts with the previous board's action items copied into *From last retro*.
- **Cards**: add with Enter, inline edit, delete, author shown on the card.
- **Drag & drop**: reorder inside a column, move between columns, or drop a card on top of another
  card to **merge** them (votes and reactions follow). Merged cards can be split again.
- **Voting** with a max number of votes per person (default 6), remove your vote again.
- **Emoji reactions** on every card; hover a reaction to see who reacted.
- **Board options**: hide other people's cards per column while brainstorming (eye button in the column header), hide vote counts,
  change max votes, sort by manual order or most votes.
- **Timer** (1–15 min presets, +1 min, stop) shared with the whole team, beeps when done.
- **Live updates**: every change is broadcast to everyone on the board via Turbo Streams.

## Running it

```bash
bin/setup            # installs gems, prepares the database
bin/rails db:seed    # optional example board
bin/rails server
```

Open http://localhost:3000, log in with password `retro`, enter your name.

Run the tests with `bin/rails test`, or the whole CI pipeline (style, security, tests) with `bin/ci`.

## Docker

```bash
docker build -t team-retro .
docker run -d -p 80:80 \
  -e TEAM_PASSWORD=change-me \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e FORCE_SSL=false \
  -v team-retro-storage:/rails/storage \
  --name team-retro team-retro
```

The image runs Puma behind [Thruster](https://github.com/basecamp/thruster) on port 80 and
prepares the SQLite databases on start. Leave out `FORCE_SSL=false` when running behind an
HTTPS reverse proxy.

## Deploying with Kamal

The app ships with the standard Rails [Kamal](https://kamal-deploy.org) setup:

1. Edit `config/deploy.yml`: set your server IP, the registry user / image name and the `proxy.host` domain.
2. Provide the secrets Kamal injects (see `.kamal/secrets`): `KAMAL_REGISTRY_PASSWORD`,
   `RAILS_MASTER_KEY` (from `config/master.key`) and `TEAM_PASSWORD`.
3. `bin/kamal setup` for the first deploy, `bin/kamal deploy` afterwards.

Every push to `main` is deployed automatically by the `deploy` job at the end of the CI workflow,
once all other jobs pass. It needs the repository secrets `SSH_PRIVATE_KEY`, `RAILS_MASTER_KEY`,
`KAMAL_REGISTRY_PASSWORD` and `TEAM_PASSWORD`, plus the repository variable `SSH_KNOWN_HOSTS`
holding the server's host keys (`ssh-keyscan 62.238.15.241`).

## Production notes

- Set `TEAM_PASSWORD` (the app refuses to boot in production without it) and `SECRET_KEY_BASE`.
- Live updates use Solid Cable (SQLite) in production, no Redis needed.
- Data lives in `storage/*.sqlite3`; back that directory up (in Docker, mount a volume there).
- `FORCE_SSL=false` disables the HTTPS redirect for plain-HTTP setups.
