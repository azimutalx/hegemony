-- Hegemony PvP: o unico NPC que negocia em Venore.
--
-- Compra o equipamento dos kits (o saque de quem morreu) e vende tres
-- coisas: Stone Skin Amulet, Might Ring e a Runa do Cacador (para roubar o
-- Dragao de Venore; ver dragao.lua). O kit de UM personagem vale
-- exatamente o preco de um dos dois (PRECO), em qualquer um dos cinco kits:
--
--   MS/ED       : yalahari mask 1000 + blue robe 1500 + blue legs 1500
--                 + varinha/cajado 1500 + spellbook 1500 + boots of haste 3000
--   EK (escudo) : zaoan helmet 1000 + zaoan armor 2000 + zaoan legs 1500
--                 + magic sword 1500 + shield of corruption 1000 + boots 3000
--   EK (Avenger): zaoan helmet 1000 + zaoan armor 2000 + zaoan legs 1500
--                 + avenger 2500 + boots of haste 3000
--   RP          : zaoan helmet 1000 + paladin armor 2500 + zaoan legs 1500
--                 + ironworker 2000 + boots of haste 3000
--                                                    todos = 10000
--
-- A VENDA E POR CONVERSA ("vender"), NAO PELA JANELA DE TROCA: o motor so
-- avisa o Lua depois que a venda pela janela ja aconteceu (Npc::onPlayerSellItem),
-- e aqui a venda precisa ser recusada quando o item e do proprio vendedor
-- (marca Hegemony.DONO, posta no kit por renascer.lua). A janela de troca fica
-- so para comprar.
--
-- Fica longe de zona protegida de proposito: quem vem vender carrega o saque,
-- e quem sai com o ouro pode ser o proximo saque. O ponto e o tile de rua de
-- Venore mais distante de PZ que tem 3x3 livre em volta (medido na grade).

Hegemony = Hegemony or {}

local NOME = "Varg"
local POSICAO = Position(32883, 32126, 6)
local PRECO = 10000

local COMPRA = {
	[3079] = 3000, -- boots of haste
	[10385] = 1000, -- zaoan helmet
	[8864] = 1000, -- yalahari mask
	[10384] = 2000, -- zaoan armor
	[10387] = 1500, -- zaoan legs
	[8063] = 2500, -- paladin armor
	[3567] = 1500, -- blue robe
	[645] = 1500, -- blue legs
	[16096] = 1500, -- wand of defiance
	[16118] = 1500, -- glacial rod
	[8075] = 1500, -- spellbook of lost souls
	[3288] = 1500, -- magic sword
	[11688] = 1000, -- shield of corruption
	[6527] = 2500, -- the avenger
	[8025] = 2000, -- ironworker
}

local npcType = Game.createNpcType(NOME)
local npcConfig = {}

npcConfig.name = NOME
npcConfig.description = "Varg, o receptador"
npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0
npcConfig.outfit = {
	lookType = 151, -- pirata: capa escura e cara de quem nao faz pergunta
	lookHead = 114,
	lookBody = 76,
	lookLegs = 76,
	lookFeet = 114,
	lookAddons = 0,
}
npcConfig.flags = { floorchange = false, profession = "trader" }
npcConfig.speechBubble = SPEECHBUBBLE_TRADE

local RUNA = Hegemony.RUNA_DO_CACADOR -- dragao.lua carrega antes (ordem alfabetica)

npcConfig.shop = {
	{ itemName = "stone skin amulet", clientId = 3081, buy = PRECO },
	{ itemName = "might ring", clientId = 3048, buy = PRECO },
}
if RUNA then
	table.insert(npcConfig.shop, { itemName = RUNA.nome, clientId = RUNA.id, buy = RUNA.preco })
end

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end
npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end
npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end
npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end
npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end
npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end
-- A runa sai com a marca de compra e o nome dela: a runa em branco comum (a
-- conjurada) nao fere o dragao. Por isso nao passa pelo npc:sellItem.
local function venderRuna(player, amount, totalCost)
	if not player:removeMoneyBank(totalCost) then
		player:sendCancelMessage("Voce nao tem ouro suficiente.")
		return
	end
	local entregues = 0
	for _ = 1, amount do
		local item = Game.createItem(RUNA.id, 1)
		item:setActionId(RUNA.aid)
		item:setAttribute(ITEM_ATTRIBUTE_NAME, RUNA.nome)
		item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, RUNA.descricao)
		if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
			item:remove()
			break
		end
		entregues = entregues + 1
	end
	if entregues < amount then
		player:addMoney((amount - entregues) * RUNA.preco)
		player:sendCancelMessage("Sem espaco para todas as runas: o troco voltou.")
	end
end

npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	if RUNA and itemId == RUNA.id then
		venderRuna(player, amount, totalCost)
		return
	end
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost) end
npcType.onCheckItem = function(npc, player, clientId, subType) end

-- So o que esta DENTRO da mochila entra na venda: o que esta vestido nunca e
-- vendido sem querer.
local function juntarSaque(player)
	local guid = player:getGuid()
	local venda, total, proprios = {}, 0, 0
	local mochila = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not mochila or not mochila:isContainer() then
		return venda, total, proprios
	end
	for _, item in ipairs(mochila:getItems(true)) do
		local preco = COMPRA[item:getId()]
		if preco then
			if item:getCustomAttribute(Hegemony.DONO) == guid then
				proprios = proprios + 1
			else
				venda[#venda + 1] = item
				total = total + preco
			end
		end
	end
	return venda, total, proprios
end

local function tabela()
	local nomes = {}
	for id, preco in pairs(COMPRA) do
		nomes[#nomes + 1] = string.format("%s %d", ItemType(id):getName(), preco)
	end
	table.sort(nomes)
	return table.concat(nomes, ", ")
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "vender") or MsgContains(message, "sell") then
		local venda, total, proprios = juntarSaque(player)
		if #venda == 0 then
			if proprios > 0 then
				npcHandler:say("Isso ai e teu mesmo. Eu so compro o que voce tirou dos outros.", npc, creature)
			else
				npcHandler:say("Nao vejo nada que me interesse na tua mochila. Traz o equipamento de quem voce derrubar.", npc, creature)
			end
			return true
		end
		for _, item in ipairs(venda) do
			item:remove()
		end
		player:addMoney(total)
		local aviso = proprios > 0 and " O que e teu mesmo ficou contigo." or ""
		npcHandler:say(string.format("Fechado: %d peca(s) por %d de ouro.%s", #venda, total, aviso), npc, creature)
	elseif MsgContains(message, "preco") or MsgContains(message, "lista") then
		local runa = RUNA and (", e a {runa do cacador} por " .. RUNA.preco) or ""
		npcHandler:say("Pago: " .. tabela() .. ". Vendo {stone skin amulet} e {might ring} por " .. PRECO .. " cada" .. runa .. ": diga {comprar}.", npc, creature)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Psst, |PLAYERNAME|. Equipamento de quem caiu eu compro: diga {vender}. Protecao eu vendo: diga {comprar}. Quer a {lista}?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Some daqui antes que te vejam comigo.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "...")
npcHandler:setMessage(MESSAGE_SENDTRADE, "Olha ai. Sem choro depois.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

local foco = FocusModule:new()
npcHandler:addModule(foco, npcConfig.name, true, true, true)
-- Palavras em portugues alem das padrao (hi, bye, trade), so neste NPC.
for _, palavra in ipairs({ "oi", "ola", "salve" }) do
	keywordHandler:addKeyword({ palavra, callback = FocusModule.messageMatcher }, FocusModule.onGreet, { module = foco })
end
keywordHandler:addKeyword({ "tchau", callback = FocusModule.messageMatcher }, FocusModule.onFarewell, { module = foco })
keywordHandler:addKeyword({ "comprar", callback = FocusModule.messageMatcher }, FocusModule.onTradeRequest, { module = foco })

npcType:register(npcConfig)

-- Nasce por script (como o Rashid do upstream), nao pelo arquivo de spawn:
-- assim o NPC e o lugar dele ficam juntos neste arquivo.
local nascer = GlobalEvent("HegemonyReceptador")
function nascer.onStartup()
	local npc = Game.createNpc(NOME, POSICAO)
	if npc then
		npc:setMasterPos(POSICAO)
		logger.info("[Hegemony] receptador em {},{},{}", POSICAO.x, POSICAO.y, POSICAO.z)
	else
		logger.error("[Hegemony] receptador nao nasceu em {},{},{}", POSICAO.x, POSICAO.y, POSICAO.z)
	end
	return true
end
nascer:register()
