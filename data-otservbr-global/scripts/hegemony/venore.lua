-- Hegemony PvP: o mundo e so Venore, a cidade inteira, todos os andares.
--
-- COMO A CIDADE FOI MEDIDA (18/09/2026)
--
-- Venore e uma cidade elevada: as ruas ficam no andar 6, sobre o pantano do
-- andar 7, e o templo e o deposito sao ilhas do andar 7 ligadas as ruas por
-- escada. Um levantamento pediu ao proprio servidor a grade de x 32780-33120,
-- y 31930-32230, andares 0 a 15 (andavel, protegido, casa, escada que sobe ou
-- desce, teleporte), e uma busca a partir do templo, respeitando o sentido de
-- cada escada, separou a cidade do resto do mundo:
--
--   - 5.288 tiles alcancaveis do andar 2 ao 11 (ruas, predios, esgoto);
--   - exatamente 6 saidas: escadas e alcapoes das ruas que descem para o
--     pantano ou para o continente. Sem elas, nada do que se alcanca sai do
--     retangulo abaixo, em andar nenhum.
--
-- As 6 escadas viram o piso vizinho a cada boot (o mapa nao e salvo, so as
-- casas). A zona e a rede de seguranca para o resto: levitate, teleporte de
-- script (pedra dos aventureiros, Fury Gate, santuarios), barco. Barcos e
-- carruagem nem existem: os NPCs de Venore sairam do spawn (ver
-- world/otservbr-npc.xml e o compose).

Hegemony = Hegemony or {}

Hegemony.VENORE = {
	cidade = 9, -- TOWNS_LIST.VENORE
	templo = Position(32957, 32076, 7),
	de = Position(32855, 32005, 0),
	ate = Position(33030, 32165, 15),
}

-- escada = id do chao que hoje e a escada; piso = chao mais comum entre os
-- vizinhos andaveis do mesmo andar, conferido no .otbm.
local ESCADAS_DE_SAIDA = {
	{ pos = Position(32862, 32126, 6), escada = 413, piso = 17464 }, -- stairs -> cobblestone
	{ pos = Position(32867, 32032, 6), escada = 484, piso = 16484 }, -- trapdoor -> grimy wooden plank
	{ pos = Position(32888, 32056, 6), escada = 4826, piso = 17468 }, -- stairs -> cobblestone
	{ pos = Position(32907, 32028, 6), escada = 434, piso = 16484 }, -- trapdoor -> grimy wooden plank
	{ pos = Position(32936, 32159, 6), escada = 413, piso = 17464 }, -- stairs -> cobblestone
	{ pos = Position(32965, 32110, 6), escada = 4826, piso = 17505 }, -- stairs -> plaster
}

local zona = Zone("hegemony.venore")
zona:addArea(Hegemony.VENORE.de, Hegemony.VENORE.ate)

-- A zona e um retangulo: comparar coordenadas e exato e nao depende de API.
function Hegemony.dentroDeVenore(pos)
	local de, ate = Hegemony.VENORE.de, Hegemony.VENORE.ate
	return pos.x >= de.x and pos.x <= ate.x and pos.y >= de.y and pos.y <= ate.y and pos.z >= de.z and pos.z <= ate.z
end

local function texto(pos)
	return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

-- GM continua livre para sair e entrar: e quem conserta o mapa.
function Hegemony.livre(player)
	return player:getGroup():getAccess()
end

local fechar = GlobalEvent("HegemonyFecharVenore")
function fechar.onStartup()
	local fechadas = 0
	for _, e in ipairs(ESCADAS_DE_SAIDA) do
		local tile = Tile(e.pos)
		local chao = tile and tile:getGround()
		if not chao then
			logger.error("[Hegemony] sem chao em {}: escada de saida continua aberta", texto(e.pos))
		elseif chao:getId() ~= e.escada then
			-- Mapa diferente do medido. Nao troca as cegas: registra alto.
			logger.error("[Hegemony] esperava a escada {} em {} e achei {}; nao troquei", e.escada, texto(e.pos), chao:getId())
		else
			chao:transform(e.piso)
			if Tile(e.pos):hasFlag(TILESTATE_FLOORCHANGE) then
				logger.error("[Hegemony] {} continua trocando de andar depois da troca de piso", texto(e.pos))
			else
				fechadas = fechadas + 1
			end
		end
	end
	logger.info("[Hegemony] Venore fechada: {} de {} escadas de saida viraram piso", fechadas, #ESCADAS_DE_SAIDA)
	return true
end
fechar:register()

-- Saida bloqueada em qualquer andar. O ZoneEvent devolve o retorno direto ao
-- motor e nil BLOQUEIA (medido): todo caminho termina em return.
local borda = ZoneEvent(zona)
function borda.beforeLeave(zone, creature)
	local player = creature:getPlayer()
	if not player or Hegemony.livre(player) then
		return true
	end
	player:sendTextMessage(MESSAGE_FAILURE, "Nao ha nada alem de Venore.")
	return false
end
borda:register()

-- Quem entra fora de Venore (personagem antigo, ou salvo em outra cidade) vai
-- para o templo. A cidade natal vira Venore para todos, porque e para o templo
-- dela que o motor manda quem morre.
local chegada = CreatureEvent("HegemonyChegadaVenore")
function chegada.onLogin(player)
	if Hegemony.livre(player) then
		return true
	end
	if player:getTown():getId() ~= Hegemony.VENORE.cidade then
		player:setTown(Town(Hegemony.VENORE.cidade))
	end
	if not Hegemony.dentroDeVenore(player:getPosition()) then
		player:teleportTo(Hegemony.VENORE.templo)
		Hegemony.VENORE.templo:sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end
chegada:register()
