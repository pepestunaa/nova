# Astralis

Server emulator for Stella Sora. 

This project is not affiliated with the game's developers or publisher.

## Contents

- [Compatibility](#compatibility)
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

**Current supported client version:** `1.13.0.131`

The server is tested against the version above. Game updates may take time to
receive compatible resources or protocol changes, and the repository is not
guaranteed to support the latest client version.

## What works

Astralis currently focuses on Recruitment and Ascension.

### Recruitment

- Newbie and regular gacha banners, including pulls, costs, rewards, guarantees, and collection progress.

### Character progression

- Leveling, skill upgrades, talents.

### Daily and weekly missions

- Daily and weekly mission lists, scheduled resets, and individual or bulk
  reward claims.
- Progress for login, Ascension entry/completion and battles, character and
  Disc level-ups, and the daily shop reward.
- Daily and weekly activity rewards.

### Ascension

- Starting, resuming, leaving, and completing runs.
- Combat rooms, events, recovery rooms, shops, Potentials, Musical Notes, Harmony Skills, and the Enhancement Machine.
- Journey Tickets, first-clear and give-up rewards, NPC affinity, and Ascension records.
- Record saving, dismantling, locking, naming, and preferences.
- Monolith Research upgrades, plus Research Project quests and rewards for supported Ascension actions.

## Still in progress

Some parts are not complete yet, or may still differ from the
official server:

- A few advanced Monolith Research effects and unusual Ascension events need more refinement.
- Fate Cards and Cataclysm Survivor are not implemented yet.
- Daily missions use the observed 10 fixed entries plus 2 rotating entries.
  The official selection formula is unknown, so the exact pair sequence may
  differ.
- Some daily and weekly missions are tied to systems or activities that are not
  implemented (at least yet), so those missions will not progress for now.
- Character emblems are not implemented yet.

## Client patch

You will need [Asterism](https://git.xeondev.com/nyan/asterism).
It makes the game request from your local server instead of the official server.

## Prebuilt executables

Prebuilt binaries are available from the [release page](https://git.xeondev.com/nyan/astralis/releases), 
extract the compressed file anywhere, then start both servers from the extracted folder.

## Automatic setup

The installer downloads Astralis and prepares the right Zig version for you. On
Windows, open PowerShell and run:

```powershell
irm https://git.xeondev.com/nyan/astralis/raw/branch/main/scripts/install.ps1 | iex
```

On Linux, run:

```sh
curl -fsSL https://git.xeondev.com/nyan/astralis/raw/branch/main/scripts/install.sh | sh
```

Windows can install Git automatically. On Linux, the installer will tell you
which tools are missing so you can install them with your distribution's
package manager. If Zig is missing or has the wrong version, the installer can
set it up through [zvm](https://git.xeondev.com/nyan/zvm).

Once installation finishes, Windows users can double-click
`scripts/start.cmd`. On Linux, run `sh scripts/start.sh`.

Use `scripts/update.cmd` on Windows or `sh scripts/update.sh` on Linux to update
Astralis. The updater will preserve customized server configs when they can be
merged safely, and will never discard other local changes.

## Manual setup

You will need Git and Zig `0.16.0`. Clone the repository and enter its directory:

```sh
git clone --depth=1 https://git.xeondev.com/nyan/astralis.git
cd astralis
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

Please report bugs in the [issue tracker](https://git.xeondev.com/nyan/astralis/issues).
Include steps to reproduce the problem, what you expected to happen, what
happened instead, and the relevant server or client logs (if any). Mention the Astralis
and Asterism version or commit you are using.

You can also report issues in the [Reversed Rooms Discord server](https://discord.xeondev.com/).

## Contributing

Focused pull requests are welcome. For larger features or changes to core
protocol or gameplay behavior, open an issue first so the approach can be
discussed before you spend time implementing it.

If you don't have an account you can submit patches in the Discord server.

## License

This repository was made public in the hopes that it will be useful. However, it comes with no warranty whatsoever (expressed or implied). It's licensed under [GNU Affero General Public License v3](LICENSE).
