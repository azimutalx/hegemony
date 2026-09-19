# Hegemony PvP

Servidor de Tibia focado em PvP, construído sobre o [Canary](https://github.com/opentibiabr/canary)
— motor OpenTibia em C++20 com scripts em Lua — com site MyAAC e banco MariaDB, tudo em Docker.
Projeto pessoal de Hemerson Abreu.

Este repositório é um fork do Canary. O motor e o datapack são do upstream; o que é do Hegemony
está nos commits a partir de [`57f621c47`](https://github.com/azimutalx/hegemony/commit/57f621c47).
Cada um explica a causa do problema e como a correção foi medida — o histórico é a melhor
documentação do projeto. O README original do Canary continua mais abaixo.

## Estado

- **Jogável de ponta a ponta** (protocolo 15.25): login, lista de personagens e entrada no mundo.
- **O cliente próprio (sobre o OTClient) entra no mundo desde 18/09/2026** e mora em repositório
  separado (privado), com o C++ e o Lua juntos, como no OTClient original. A causa da antiga
  dessincronização de protocolo era o cliente anunciar um sistema operacional que desligava o
  campo de sequência de 4 bytes do Canary.

## O que foi feito aqui

**Correções no datapack (Lua)**

- **Aluguel de montaria que nunca expirava.** `check_mount.lua` usava `break` onde precisava pular
  o jogador: o laço morria no primeiro jogador sem cavalo alugado, que é o caso comum.
- **Boss do dia com o nome errado.** Havia dois registros para o mesmo boss, e o sorteio publica a
  chave de registro, não `monster.name` — todo jogador via "Eradicator2" ao entrar.
- **Poção infinita gerava frasco infinito.** `potions.lua` entregava o frasco vazio antes de
  checar se a poção seria consumida.
- Scripts migrados da API procedural antiga (`doPlayerSendCancel`, `doSendMagicEffect`,
  `getPlayerGUID`) para a API orientada a objetos do motor (`player:sendCancelMessage`,
  `Position:sendMagicEffect`, `player:getGuid`).

**Infraestrutura**

- **Configuração reproduzível.** O servidor funcionava graças a um ajuste feito à mão dentro do
  container, que qualquer `docker compose down` apagaria. `docker/hegemony/entrypoint.sh` aplica a
  configuração do Hegemony antes do `start.sh` da imagem e **aborta** se uma chave esperada sumir,
  em vez de subir com o padrão do upstream sem avisar.
- **Fuso horário.** O container rodava em UTC e o Canary calcula "hoje" com `localtime()`: a
  criatura e o boss do dia trocavam às 21h de Brasília.
- Limites de memória e CPU por container, e o `OPTIMIZE TABLE` a cada boot desligado — em InnoDB
  ele reconstrói a tabela inteira e bloqueia.

**Desenho do jogo**

- Todo personagem novo nasce **nível 80**, com skills de treinado e kit infinito de runas e
  poções, e evolui normalmente depois. O MyAAC copia o personagem de um "Sample" por vocação, então
  os Samples são o molde (`docker/hegemony/02-modelos-nivel-80.sql`).

## Como rodar

Precisa de Docker.

```bash
cd docker
cp .env.dist .env
docker compose up -d
```

O primeiro boot baixa o mapa (cerca de 190 MB). Depois disso: site em `http://localhost:8080` e
login web em `http://127.0.0.1:8088/login`. O login é pelo **e-mail** da conta, não pelo nome.

As senhas que vêm nos arquivos (`docker/.env.dist`, `schema.sql`, `docker/data/*.sql`) são padrões
de desenvolvimento, as mesmas que o Canary publica. Troque-as antes de abrir o servidor para outras
pessoas.

## Créditos e licença

- Motor, datapack e ferramentas: [Canary](https://github.com/opentibiabr/canary), sob GPL-2.0 — que
  vale também para este fork (ver `LICENSE`).
- Cliente: [OTClient](https://github.com/mehah/otclient). Site: [MyAAC](https://github.com/slawkens/myaac).
- Tibia é marca da CipSoft GmbH. O cliente oficial não está neste repositório.

---

> O que segue é o README original do Canary.

# Canary

[![Discord](https://img.shields.io/discord/528117503952551936.svg?style=flat-square&logo=discord)](https://discord.gg/gvTj5sh9Mp)
[![CI](https://github.com/opentibiabr/canary/actions/workflows/ci.yml/badge.svg)](https://github.com/opentibiabr/canary/actions/workflows/ci.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=opentibiabr_canary&metric=alert_status)](https://sonarcloud.io/dashboard?id=opentibiabr_canary)
![Repository size](https://img.shields.io/github/repo-size/opentibiabr/canary)
[![License](https://img.shields.io/github/license/opentibiabr/canary.svg)](https://github.com/opentibiabr/canary/blob/main/LICENSE)

Canary is a free and open-source MMORPG server emulator for the OpenTibia community, written in C++20 and Lua. It is a fork of the [OTServBR-Global](https://github.com/opentibiabr/otservbr-global) project. The repository includes the server core, datapacks, Lua scripts, database schema, build presets, automated tests and development tooling used by the project.

---

## Getting Started

- [Wiki](https://github.com/opentibiabr/canary/wiki).

---

## Docker Quickstart

Canary includes a lightweight Docker quickstart for running a local test server
without compiling Canary locally. The stack starts MariaDB, the published Canary
runtime image, MyAAC as the website/admin AAC, and `opentibiabr/login-server` as
the client login webservice.

This quickstart is for local development, testing, and LAN demos. Do not expose
it directly to the public Internet with the default test accounts and passwords.

Run from the `docker` directory:

```bash
cp .env.dist .env
docker compose up -d --build
```

The `docker` directory also provides guarded start scripts that start the stack
and clean safe Docker leftovers without removing database volumes:

```powershell
.\up.ps1
```

```bash
sh ./up.sh
```

Default local endpoints:

- Website/admin: `http://localhost:8080`
- Client login webservice: `http://localhost:8088/login`
- Game port: `7172`

MyAAC's `login.php` is intentionally removed from the quickstart image. Clients
should use `login-server` only. See [docs/docker/quickstart-for-beginners.md](docs/docker/quickstart-for-beginners.md)
for a beginner guide and [docker/DOCKER.md](docker/DOCKER.md) for the full setup,
environment variables, test account, and troubleshooting guide.

---

## Documentation

- [Shared build cache for worktrees and forks](docs/development/shared-build-cache.md).
- [Docker beginner quickstart](docs/docker/quickstart-for-beginners.md).
- [Multiprotocol runtime profiles](docs/systems/multiprotocol.md). Covers the
  current, 11.00, and 8.60 runtime contracts, port layout, client preparation,
  and validation checklist.
- [System documentation](docs/systems/README.md).
- [Lua API reference and VSCode IntelliSense stubs](docs/lua-api/lua_api.md). Canary generates these files from the C++ Lua bindings during startup when `generateLuaApiDocs` is enabled. The repository `.luarc.json` already adds `docs/lua-api` to the Lua Language Server workspace library; for VSCode workspace settings, run `tools/setup_vscode_lua_api.ps1`.

---

## Recommended Tools and Clients

- [Assets Editor](https://github.com/Arch-Mina/Assets-Editor). Use this as the
  single asset source of truth, then export legacy-compatible `.dat`/`.spr`
  packages for 8.60 clients from the same current asset set.
- [Remere's Map Editor](https://github.com/opentibiabr/remeres-map-editor/).
- [OTClient Redemption](https://github.com/opentibiabr/otclient).
- [Tibia Extended Client Library](https://github.com/dudantas/Tibia-Extended-Client-Library).
  Use this to prepare compatible 8.60/11.00 CipSoft clients with extended
  limits, config-driven login redirect, and per-client local state.
- [Game Client](https://github.com/dudantas/tibia-client/releases/latest).

---

## Nightly Packages

Development builds can be downloaded from GitHub Actions artifacts. They are useful for testing recent changes from the `main` branch, but may include behavior that is not present in stable releases yet.

- [Github Actions](https://github.com/opentibiabr/canary/actions/workflows/ci.yml?query=branch%3Amain).

---

## Running Tests

Tests can be run from the repository root using the tool versions and tasks
pinned in `.mise.toml`:

```bash
mise install
mise run configure linux-debug
mise run build linux-debug
mise run test linux-debug

# Replace linux-debug with macos-debug or windows-debug as needed.
```

For detailed testing information including adding tests and framework usage, see [tests/README.md](tests/README.md).

---

## Support & Community

For real-time support, join the [OpenTibiaBR Discord](https://discord.gg/gvTj5sh9Mp).

The GitHub issue tracker should be used for bugs, improvements and technical project tasks. It is not a support forum.

---

## Contributing

Contributions are welcome. You can help in several ways:

- Report bugs through the [Issue Tracker](https://github.com/opentibiabr/canary/issues/new/choose).
- Submit improvements through [Pull Requests](https://github.com/opentibiabr/canary/pulls).
- Improve tests, documentation, scripts, datapacks, or C++ code.
- Validate releases, nightly builds and recent changes.

Before contributing, read the [Code of Conduct](https://github.com/opentibiabr/canary/blob/main/CODE_OF_CONDUCT.md) and the project [Contributing](https://github.com/opentibiabr/canary/blob/main/CONTRIBUTING.md) guide.

---

## Sponsorship

Canary is maintained by community contributors. To support development, visit the [OpenTibiaBR sponsors page](https://github.com/sponsors/opentibiabr).

---

## Acknowledgements

Thanks to all contributors of [Canary](https://github.com/opentibiabr/canary/graphs/contributors), [OTServBR-Global](https://github.com/opentibiabr/otservbr-global/graphs/contributors) and the OpenTibia community.

---

## License

This project is distributed under the [GPL-2.0 license](https://github.com/opentibiabr/canary/blob/main/LICENSE).
