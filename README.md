# Team Retro

A small, self-hosted clone of the default [EasyRetro](https://easyretro.io) board for **one team**.
Built with Rails 8, Hotwire (Turbo + Stimulus) and SQLite. No accounts: everybody shares one
team password and picks a display name.

## Features

- **Login with one team password** (`TEAM_PASSWORD`, defaults to `retro` in development).
- **Name modal** pops up when the session has no name yet; click your name in the header to change it.
- **Dashboard** of all boards with card counts, create / delete boards, CSV export.
- **Classic board**: *Went Well* · *To Improve* · *Action Items* (columns are fixed).
- **Cards**: add with Enter, inline edit, delete, author shown on the card.
- **Drag & drop**: reorder inside a column, move between columns, or drop a card on top of another
  card to **merge** them (votes and comments follow). Merged cards can be split again.
- **Voting** with a max number of votes per person (default 6), remove your vote again.
- **Comments** on every card.
- **Board options**: hide other people's cards per column while brainstorming (eye button in the column header), hide vote counts,
  hide authors, change max votes, sort by manual order / newest / most votes.
- **Timer** (1–15 min presets, +1 min, stop) shared with the whole team, beeps when done.
- **Text filter** for cards.
- **Live updates**: every change is broadcast to everyone on the board via Turbo Streams.

## Running it

```bash
bin/setup            # installs gems, prepares the database
bin/rails db:seed    # optional example board
bin/rails server
```

Open http://localhost:3000, log in with password `retro`, enter your name.

Run the tests with `bin/rails test`.

## Docker

```bash
docker build -t team-retro .
docker run -d -p 3000:3000 \
  -e TEAM_PASSWORD=change-me \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e FORCE_SSL=false \
  -v team-retro-storage:/rails/storage \
  --name team-retro team-retro
```

The container prepares the SQLite databases on start. Leave out `FORCE_SSL=false` when
running behind an HTTPS reverse proxy.

## Production notes

- Set `TEAM_PASSWORD` (the app refuses to boot in production without it) and `SECRET_KEY_BASE`.
- Live updates use Solid Cable (SQLite) in production, no Redis needed.
- Data lives in `storage/*.sqlite3`; back that directory up (in Docker, mount a volume there).
- `FORCE_SSL=false` disables the HTTPS redirect for plain-HTTP setups.
