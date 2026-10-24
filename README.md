# Nova

![banner](docs/image.png)

Server emulator for Stella Sora. Nova is not affiliated with the game's
publisher or developers.

Nova is a fork of [Astralis](https://git.xeondev.com/nyan/astralis) by nyan.
It is licensed under [GNU AGPL v3](LICENSE).

## Compatibility

Nova is currently tested with client `2.0.0.144`. It still uses game tables
from `1.13.0.139` and `1.13.0.143`, so some newer characters, items, and shop
products may be missing.

You also need [Asterism](https://git.xeondev.com/nyan/asterism) to redirect the
client to the local server.

## Features

The main supported systems are:

- Recruitment, including newbie banners, pity, rewards, and collection progress
- Character levels, advancement, skills, talents, and potentials
- Disc strengthening, promotion, and limit breaks
- Ascension runs, combat rooms, events, shops, records, and rewards
- Daily and weekly missions, activity rewards, achievements, and progression
- Monolith Research and supported Research Project rewards
- Handbook and gallery unlocks, including the newer decor gallery
- Accounts, profiles, formations, and basic friend state
- Shop listings, daily rewards, gem conversion, monthly cards, packages, and
  in-game purchases

Real-money gem and monthly-card purchases are disabled by default. Packages grant
their configured rewards directly. Real-money purchases require a client patch
that handles the Steam payment callback.

## Known limitations

- Fate Cards and Cataclysm Survivor are not implemented.
- Dorm, potential presets, partner-trace details, and some activity systems are
  only partially implemented or acknowledged for client compatibility.
- Some advanced Monolith Research effects and Ascension events need refinement.
- Daily missions use 10 fixed entries and 2 rotating entries. The official
  rotation formula is unknown.
- Missions for unsupported systems will not progress.
- Character emblems are not implemented.
- The remaining `2.0.0.144` character, item, and shop tables still need to be
  extracted.

## Installation

### Prebuilt binaries

Download the latest build from the [release page](https://github.com/pepestunaa/nova/releases),
extract it, and run both server executables.

### Automatic setup

Windows PowerShell:

```powershell
irm https://github.com/pepestunaa/nova/raw/branch/main/scripts/install.ps1 | iex
```

Linux:

```sh
curl -fsSL https://github.com/pepestunaa/nova/raw/branch/main/scripts/install.sh | sh
```

After installation, start Nova with `scripts/start.cmd` on Windows or
`scripts/start.sh` on Linux. Use the matching `update` script to update it.

### Manual setup

Requirements: Git and Zig `0.16.0`.

```sh
git clone --depth=1 https://github.com/pepestunaa/nova.git
cd nova
zig build -Doptimize=ReleaseSafe serve-all
```

The SDK server listens on `127.0.0.1:20001` and the game server listens on
`127.0.0.1:20002` by default. To build without starting the servers:

```sh
zig build -Doptimize=ReleaseSafe
```

The servers can also be started separately with `run-sdk-server` and
`run-game-server`. Addresses and other settings are configured in
`servers/sdk/config.zon` and `servers/game/config.zon`. Player data is stored in
`store`.

## Documentation

See the [technical documentation](docs/README.md) for contributor information.

## Support

Report bugs in the [issue tracker](https://github.com/pepestunaa/nova/issues).
Include reproduction steps, expected and actual behavior, logs, and the Nova
and Asterism versions you are using.

You can also ask for help in the [Reversed Rooms Discord server](https://discord.xeondev.com/).

Focused pull requests are welcome. For larger changes, open an issue first.
