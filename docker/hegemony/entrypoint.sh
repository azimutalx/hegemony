#!/usr/bin/env bash
#
# Entrypoint do Hegemony PvP.
#
# POR QUE ISTO EXISTE
#
# O servico `server` roda a imagem publicada `ghcr.io/opentibiabr/canary`, que
# ja traz um `/canary/config.lua` de fabrica. O `start.sh` da imagem reescreve
# nele apenas 15 chaves (banco, nome, ip, portas, datapack, url do mapa) — todo
# o resto fica com o padrao do upstream.
#
# Ate 18/09/2026 as configuracoes do Hegemony que nao estao nessas 15 chaves
# viviam **editadas a mao dentro do container**. Funcionava, e era invisivel:
# nao aparecia em arquivo nenhum, nao estava no git, e um `docker compose down`
# ou um `--force-recreate` devolvia tudo ao padrao do upstream sem avisar.
# Medido no dia: a imagem trazia `packetCompressionLevel = 6` e o container
# rodava com `0`, sem que nada no repositorio explicasse a diferenca.
#
# Este script torna essa configuracao reproduzivel. Ele roda ANTES do
# `start.sh`, que so mexe nas 15 chaves dele e portanto preserva estas.
#
# REGRA IMPORTANTE: se uma chave nao existir no config.lua da imagem, este
# script **aborta**. Nao seguir em silencio e o ponto: a alternativa seria o
# servidor subir com o padrao do upstream e ninguem perceber, que e exatamente
# a falha que motivou este arquivo.

set -euo pipefail

CONFIG=/canary/config.lua

set_config() {
	local chave="$1" valor="$2"

	if ! grep -qE "^[[:space:]]*${chave}[[:space:]]*=" "$CONFIG"; then
		echo "ERRO: a chave '${chave}' nao existe em ${CONFIG}." >&2
		echo "      A imagem do Canary mudou o config padrao. Ajuste" >&2
		echo "      docker/hegemony/entrypoint.sh antes de subir o servidor." >&2
		exit 1
	fi

	sed -i -E "s|^[[:space:]]*${chave}[[:space:]]*=.*|${chave} = ${valor}|" "$CONFIG"
	echo "  ${chave} = ${valor}"
}

echo ""
echo "===== Configuracao do Hegemony ====="
echo ""

# Medido em 18/09/2026: com compressao ligada o cliente oficial 15.25 nunca foi
# testado, e o valor 0 e o unico estado em que o servidor foi observado jogavel
# de ponta a ponta. Mantido em 0 ate existir medicao com 6.
set_config packetCompressionLevel 0

# O servidor se chama "Hegemony PvP" e a imagem sobe em "retro-pvp".
set_config worldType '"pvp-enforced"'

# Teto de saturacao. Sem ele o servidor aceita login ate degradar; com ele,
# recusa. O numero e um guarda-corpo para o teste fechado, nao uma medicao.
set_config maxPlayers 100

# `OPTIMIZE TABLE` por tabela a cada boot. Em InnoDB isso e rebuild completo e
# bloqueante: com player_items grande, sao minutos de arranque a cada restart.
set_config startupDatabaseOptimization false

# Suprimentos infinitos: rune, pocao, municao e arma com carga nunca se gastam.
# O motor ja suporta isso nativamente (spells.cpp, weapons.cpp, potions.lua).
# Atencao: potions.lua entregava frasco vazio a cada gole mesmo sem consumir a
# pocao — corrigido no datapack e montado pelo compose.
set_config removeChargesFromRunes false
set_config removeChargesFromPotions false
set_config removeWeaponAmmunition false
set_config removeWeaponCharges false

# Os personagens nascem promovidos (MS, ED, RP, EK). O login.lua rebaixa
# promovido em conta sem premium A CADA LOGIN: sem isto, um ED criado numa conta
# gratis viraria Druid comum na primeira entrada.
set_config freePremium true

echo ""
exec /canary/start.sh "$@"
