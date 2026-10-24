# Nova

![banner](docs/image.png)

Server emulator for Stella Sora. 

This project is not affiliated with the game's developers or publisher.

Nova is a fork of [Astralis](https://git.xeondev.com/nyan/astralis) by nyan,
which is licensed under the GNU Affero General Public License v3. The original
copyright and license notices are kept in the `LICENSE` file.

## Contents

- [Compatibility](#compatibility)
- [Getting started](#getting-started)
- [What works](#what-works)
- [Still in progress](#still-in-progress)
- [Client patch](#client-patch)
- [Prebuilt executables](#prebuilt-executables)
- [Automatic setup](#automatic-setup)
- [Manual setup](#manual-setup)
- [Technical documentation](#technical-documentation)
- [Bug reports](#bug-reports)
- [Contributing](#contributing)
- [License](#license)

## Compatibility

**Current supported client version:** `2.0.0.144`

The server is tested against the version above. Most bundled game tables
still come from `1.13.0.139` and `1.13.0.143`; the tables the newer client
added are being extracted one at a time, so a few items, characters and shop
products can be missing. Game updates may take time to receive compatible
resources or protocol changes, and the repository is not guaranteed to
support the latest client version.

## Getting started

The client needs [Asterism](#client-patch) (client patch) before it can connect to Nova.
Once you have that, choose whichever setup method suits you:

- [Prebuilt executables](#prebuilt-executables) if you want to download and run
  the server directly.
- [Automatic setup](#automatic-setup) if you want the scripts to clone the
  repository and prepare Zig for you.
- [Manual setup](#manual-setup) if you prefer to install the requirements and
  build it yourself.

After setup, run both server executables (or start both servers through the
provided scripts), then launch the patched client.

## What works

Nova currently focuses on the core single-player progression loop, Recruitment,
and Ascension. The server also provides compatibility responses for several
client systems that are not implemented yet, so the current client can reach
the main menu without getting stuck on those requests.

### Recruitment

- Newbie and regular Recruitment banners, including pulls, costs, rewards,
  guarantees, pity storage, and collection progress.
- Unknown banners can use the shared pools for their pity group, which keeps
  newer client banners usable when their table rows have not been extracted
  yet.
- The current development configuration selects the featured five-star pool
  for pulls rather than using the configured featured probability.

### Character and Disc progression

- Character leveling, advancement, skill upgrades, talents, and potential
  nodes.
- Disc strengthening, promotion, and limit breaks.
- Handbook and gallery unlocks, including the decor gallery rows added by the
  `2.0.0.144` client.

### Missions and progression

- Daily and weekly mission lists, scheduled resets, and individual or bulk
  reward claims.
- Progress for login, Ascension entry/completion and battles, character and
  Disc level-ups, and the daily shop reward.
- Daily and weekly activity rewards, achievements, and client-reported
  progression events.
- Monolith Research upgrades and Research Project quests and rewards for
  supported Ascension actions.

### Ascension

- Starting, resuming, leaving, and completing runs.
- Combat rooms, events, recovery rooms, shops, Potentials, Musical Notes,
  Harmony Skills, and the Enhancement Machine.
- Journey Tickets, first-clear and give-up rewards, NPC affinity, and
  Ascension records.
- Record saving, dismantling, locking, naming, and preferences.

### Shop and account systems

- Account creation and login, player profiles, names, signatures, titles,
  head icons, formations, and basic friend state.
- Shop listings, daily shop rewards, gem conversion, monthly cards, packages,
  and in-game shop purchases.
- Real-money gem and monthly-card topups are disabled by default. Package
  orders grant their configured rewards directly; enabling real-money topups
  requires a client patch that handles the Steam payment callback.

## Still in progress

Some parts are not complete yet, or may still differ from the official server:

- A few advanced Monolith Research effects and unusual Ascension events need
  more refinement.
- Fate Cards and Cataclysm Survivor are not implemented yet. The Fate Card
  detail response is only an empty compatibility response.
- Potential presets, Dorm, phone contacts, partner-trace details, and some
  activity detail systems are only partially implemented or acknowledged for
  client compatibility.
- Daily missions use the observed 10 fixed entries plus 2 rotating entries.
  The official selection formula is unknown, so the exact pair sequence may
  differ.
- Some daily and weekly missions are tied to systems or activities that are not
  implemented, so those missions will not progress for now.
- Character emblems are not implemented yet.
- The bundled tables are not yet fully refreshed for client `2.0.0.144`.
  Character, item, and shop rows introduced by that client may be unavailable
  until the remaining archive tables are extracted.

## Client patch

You will need [Asterism](https://git.xeondev.com/nyan/asterism).
It makes the game request from your local server instead of the official server.

## Prebuilt executables

Prebuilt binaries are available from the [release page](https://github.com/pepestunaa/nova/releases), 
extract the compressed file anywhere, then run both server executables from the
extracted folder.

## Automatic setup

The installer downloads Nova and prepares the right Zig version for you. On
Windows, open PowerShell and run:

```powershell
irm https://github.com/pepestunaa/nova/raw/branch/main/scripts/install.ps1 | iex
```

On Linux, run:

```sh
curl -fsSL https://github.com/pepestunaa/nova/raw/branch/main/scripts/install.sh | sh
```

Windows can install Git automatically. On Linux, the installer will tell you
which tools are missing so you can install them with your distribution's
package manager. If Zig is missing or has the wrong version, the installer can
set it up through [zvm](https://git.xeondev.com/nyan/zvm).

Once installation finishes, Windows users can double-click
`scripts/start.cmd`. On Linux, run `sh scripts/start.sh`.

Use `scripts/update.cmd` on Windows or `sh scripts/update.sh` on Linux to update
Nova. The updater will preserve customized server configs when they can be
merged safely, and will never discard other local changes.

## Manual setup

You will need Git and Zig `0.16.0`. Clone the repository and enter its directory:

```sh
git clone --depth=1 https://github.com/pepestunaa/nova.git
cd nova
```

Build the servers with:

```sh
zig build -Doptimize=ReleaseSafe
```

Or start both servers with:

```sh
zig build -Doptimize=ReleaseSafe serve-all
```

By default, the SDK server listens on `127.0.0.1:20001` and the game server
listens on `127.0.0.1:20002`. Press `Ctrl+C` to stop both services.

The servers can also be run separately:

```sh
zig build -Doptimize=ReleaseSafe run-sdk-server
zig build -Doptimize=ReleaseSafe run-game-server
```

The shared local addresses used by both servers can be overridden from the
command line. For example:

```sh
zig build -Doptimize=ReleaseSafe serve-all -- --sdk-server-address 127.0.0.1:21001 --game-server-address 127.0.0.1:21002
```

For separate listen and advertised addresses, run the servers separately.

The same settings can be changed permanently in `servers/sdk/config.zon` and
`servers/game/config.zon`.

Player data is stored in the `store` folder.

## Technical documentation

Developers who want to understand how the server works can start with
the [technical documentation index](docs/README.md).

## Bug reports

Please report bugs in the [issue tracker](https://github.com/pepestunaa/nova/issues).
Include steps to reproduce the problem, what you expected to happen, what
happened instead, and the relevant server or client logs (if any). Mention the Nova
and Asterism version or commit you are using.

You can also report issues in the [Reversed Rooms Discord server](https://discord.xeondev.com/).

## Contributing

Focused pull requests are welcome. For larger features or changes to core
protocol or gameplay behavior, open an issue first so the approach can be
discussed before you spend time implementing it.

If you don't have an account you can submit patches in the Discord server.

## License

This repository was made public in the hopes that it will be useful. However, it comes with no warranty whatsoever (expressed or implied). It's licensed under [GNU Affero General Public License v3](LICENSE).
