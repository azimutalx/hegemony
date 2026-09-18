# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Canary is an OpenTibia MMORPG server emulator (C++20 core + LuaJIT scripting), forked from OTServBR-Global. The repository contains the server core (`src/`), three datapacks, the SQL schema, CMake presets, tests, and Docker tooling.

Read [AGENTS.md](AGENTS.md) — it carries the mandatory Canary-specific gates (deferred-callback lifetime safety, PCH policy, Lua shared-userdata rules, build discipline, Docker quickstart policy). This file does not repeat them.

## Build and test

Toolchain versions and task wrappers are pinned in [.mise.toml](.mise.toml) (cmake, ninja, sccache, python; `VCPKG_ROOT` points at `.tools/vcpkg`). vcpkg is bootstrapped by `.github/scripts/bootstrap_vcpkg.py`, invoked automatically as a `depends` of every mise task.

```bash
mise install
mise run configure linux-debug      # -> cmake --preset linux-debug
mise run build     linux-debug      # -> cmake --build --preset linux-debug
mise run test      linux-debug      # -> ctest --preset linux-debug
mise run cache-stats                # sccache statistics
```

Or drive CMake directly:

```bash
cmake --preset windows-release
cmake --build --preset windows-release --target canary
```

Preset names follow `<platform>-<config>[-variant]`: `windows|linux|macos` × `release|debug`, plus `-enabled-tests`, `-asan`, `-metrics`, `-link-audit`. **Test presets only exist for `windows-debug`, `windows-release-asan`, `linux-debug`, `linux-debug-asan`, `macos-debug`** — a plain `*-release` tree has tests disabled.

Running a subset:

```bash
ctest --preset linux-debug -R unit          # unit tests only
ctest --preset linux-debug -R integration   # integration tests only
ctest --preset linux-debug -VV              # verbose, per-case output
ctest --preset linux-debug -R <TestName>    # single test by regex
./build/linux-debug/tests/unit/canary_ut --gtest_filter=FooTest.*
```

GoogleTest. New unit tests go under `tests/unit` mirroring the `src/` path and must be registered via `target_sources` in the nearest `CMakeLists.txt`. Integration tests use the disposable `canary_test` database configured by `tests/test.env` (override with `TEST_ENV_FILE`); with `TEST_DB_ALLOW_RESET=1` the runner drops and re-imports `schema.sql` when schema sentinels mismatch. See [tests/README.md](tests/README.md).

### Adding or removing C++ files

Every maintained build entry must be updated in the same change: the relevant `CMakeLists.txt`, `vcproj/canary.vcxproj`, and the test `CMakeLists.txt` when applicable. A missing `.cpp` in `vcproj/canary.vcxproj` surfaces as an unresolved external when building `vcproj/canary.sln`. Before any local build read [docs/building/local-validation.md](docs/building/local-validation.md) — its Windows preflight, `VCPKG_ROOT` restoration, cache-recovery, and MSVC Ninja dependency-tracking rules are mandatory.

## Architecture

### Core (`src/`)

- `canary_server.cpp` — startup orchestration: config load, Lua API doc generation, datapack validation, protocol/port announcement, gamestate init.
- `core.hpp` — `CLIENT_VERSION` (currently `1525`). This is the single source of truth for the "current" client protocol the server speaks.
- `server/network/` — connection, transport codecs, and `ProtocolGame`/login protocols.
- `game/`, `creatures/`, `items/`, `map/` — simulation layer.
- `lua/` — C++↔Lua bindings; `docs/lua-api/` stubs are generated from these at startup when `generateLuaApiDocs` is on.
- `pch.hpp` owns broad shared standard includes; headers must still declare their own public dependencies (see AGENTS.md).

### Multiprotocol profiles

Client-version support is **data-driven by runtime profile**, never by compile-time `CLIENT_VERSION` branches or scattered raw version comparisons. `TransportProfile` (byte envelope) / `ChallengeProfile` (who speaks first) / `AccountLoginLayout` + `GameLoginLayout` / `ProtocolProfile` (runtime client identity) are separate concerns; payload differences are gated on `ProtocolFeature` flags, not on `ProtocolProfileId::Current`.

There is **one account login port** (`7171`) and **per-profile world ports**: current → `gameProtocolPort`, 11.00 → `legacy1100GameProtocolPort`, 8.60 → `legacy860GameProtocolPort`. Account login registers a `ProtocolSessionHintStore` hint keyed by remote IP; the game socket claims that hint to pick its initial behavior. Pointing a client straight at a game port bypasses the hint and fails before the first game-login packet parses.

Before touching anything protocol-shaped, read [docs/systems/multiprotocol.md](docs/systems/multiprotocol.md) — it holds the profile table, the versioned-payload feature matrix, the add-a-profile checklist, the validation checklist, and a "common crash clues" section that maps client symptoms to the packet that leaked from the wrong profile.

### Datapacks

Three parallel datapacks; the active one is chosen by `dataPackDirectory` in `config.lua` (`CANARY_DATA_PACK` in Docker):

- `data/` — core scripts loaded first for every datapack (`data/core.lua`, `global.lua`, `stages.lua`, libs, XML).
- `data-otservbr-global/` — the full OTServBR global content (default). `scripts/`, `monster/`, `npc/`, `world/`, `raids/`, `lib/`, `startup/`.
- `data-canary/` — the slimmer Canary-native datapack.

Persistent database changes go through numbered Lua migrations in `<datapack>/migrations/`, not by editing `schema.sql` alone.

## Docker quickstart

Stack lives in [docker/](docker/) — Compose project name `otbr`, services `db` (MariaDB 11.4), `server` (published `ghcr.io/opentibiabr/canary:latest`, **not** a local build), `myaac` (website/admin, built from `slawkens/myaac` `develop`), `login-server` (client login webservice).

```bash
cd docker && cp .env.dist .env && docker compose up -d --build
```

`.\up.ps1` / `sh ./up.sh` wrap that with a data-safe cleanup (`-Lan` / `LAN=true` rewrites `.env` for other machines on the LAN; `-SkipCleanup` / `SKIP_CLEANUP=true` skips pruning). Never use `docker system prune -a --volumes` here.

Public configuration contract is the **`CANARY_*`** prefix. `docker-compose.yml` translates it into the `OT_*`, `MYSQL_*`, and MyAAC variables the images need — do not add new public settings under those legacy prefixes. The client login path is `login-server` at `http://localhost:8088/login`; MyAAC's `login.php` is deliberately deleted from the quickstart image and MyAAC stays website/admin-only on `http://localhost:8080`. Quickstart changes must be reflected in both [docker/DOCKER.md](docker/DOCKER.md) and [docs/docker/quickstart-for-beginners.md](docs/docker/quickstart-for-beginners.md).

Because `server` runs the *published* image, local `src/` edits are invisible to the running stack until a new image is built (`docker/Dockerfile.dev` is the local-compile path).

## Conventions

- Formatting is enforced by `.clang-format` (C++), `.cmake-format`/`.cmake-lint`, `.editorconfig`, and `.yamllint.yaml`. Avoid broad formatting churn in functional changes.
- `.luarc.json` already registers `docs/lua-api` as a Lua Language Server library; run `tools/setup_vscode_lua_api.ps1` for VSCode workspace settings.
- Prefer the repository's existing patterns over new abstractions; keep fixes narrow and reviewable ([.github/copilot-instructions.md](.github/copilot-instructions.md)).
- When fixing a reusable defect, audit sibling paths by behavior and ownership and fix confirmed siblings atomically — but do not turn a one-off into a speculative refactor.

## Local-only working tree

This checkout also carries untracked, non-upstream directories used for a private deployment: `hegemony-client/` and `otclient-repo/` (OTClient), `client-1525/` (official client assets), `site/` (extra PHP site served by a locally added `site` Compose service), and root-level `init.lua` / `modules/` / `config.otml` OTClient artifacts. None of these belong to Canary upstream — do not treat them as server code, and do not include them in upstream-bound changes.
