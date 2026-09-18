-- Hegemony PvP: morrer devolve o personagem ao ponto de partida.
--
-- REGRAS (18/09/2026, com o usuario)
--   - todo personagem nasce em Venore, nivel 80, com o kit da vocacao;
--   - matar da experiencia (experienceByKillingPlayers, no entrypoint);
--   - morrer derruba TUDO no corpo e o personagem volta ao nivel 80, com as
--     skills do molde e um kit novo.
--
-- O KIT E A FONTE DA VERDADE AQUI, nao no banco. Os Samples do MyAAC nascem
-- sem itens (docker/hegemony/02-modelos-nivel-80.sql); o primeiro login de um
-- personagem sem nenhum item equipado recebe o kit. Assim o kit de quem nasce
-- e o de quem renasce nunca divergem.
--
-- COMO A MORTE FUNCIONA NO MOTOR (medido no fonte)
--   1. onDeath roda com o corpo ja no chao e o personagem ainda inteiro: e
--      onde tudo e movido para o corpo e o reset fica marcado.
--   2. Player::death aplica a perda normal de nivel e skills.
--   3. Ao clicar "Ok" na tela de morte o cliente 12+ pede Player::spawn, que
--      REAPROVEITA o personagem da memoria: onLogin NAO roda. O spawn chama
--      onChangeZone, e e por ele (EventCallback playerOnChangeZone) que o
--      reset acontece. Quem fecha o cliente na tela de morte e resetado no
--      proximo login.
--
-- DONO: todo item do kit sai marcado com o guid de quem o recebeu. O
-- receptador (receptador.lua) nao compra item marcado com o guid de quem esta
-- vendendo: sem isso, vender o proprio kit, guardar o ouro e morrer de
-- proposito geraria ouro infinito.

Hegemony = Hegemony or {}
Hegemony.DONO = "hegemony_dono"

local NIVEL = 80
local KV_RESETAR = "resetar"
local KV_NASCEU = "nasceu"

-- Suprimentos: cargas e quantidades nao descem (entrypoint.sh), entao 1 basta.
local RUNAS = {
	{ 3180, 3 }, -- magic wall
	{ 3197, 3 }, -- disintegrate
	{ 3148, 3 }, -- destroy field
	{ 3192, 2 }, -- fire bomb
}

local function comRunas(extra)
	local lista = {}
	for _, r in ipairs(RUNAS) do
		lista[#lista + 1] = r
	end
	for _, r in ipairs(extra) do
		lista[#lista + 1] = r
	end
	return lista
end

-- Vida/mana/cap e skills sao os do molde de nivel 80 (a conta esta no SQL
-- dos Samples). slots: CONST_SLOT_RIGHT = mao do escudo/livro, LEFT = arma.
local MOLDES = {
	[5] = { -- Master Sorcerer
		vida = 545, mana = 2250, cap = 1190, ml = 75,
		skills = { [SKILL_SHIELD] = 25 },
		slots = {
			[CONST_SLOT_ARMOR] = 3567, -- blue robe
			[CONST_SLOT_LEGS] = 645, -- blue legs
			[CONST_SLOT_LEFT] = 16096, -- wand of defiance (nivel 65)
			[CONST_SLOT_RIGHT] = 8075, -- spellbook of lost souls (nivel 60, a maior defesa ate o 80)
			[CONST_SLOT_FEET] = 3079, -- boots of haste
		},
		mochila = comRunas({ { 238, 1 }, { 266, 1 } }), -- great mana, health potion
	},
	[6] = { -- Elder Druid
		vida = 545, mana = 2250, cap = 1190, ml = 70,
		skills = { [SKILL_SHIELD] = 25 },
		slots = {
			[CONST_SLOT_ARMOR] = 3567,
			[CONST_SLOT_LEGS] = 645,
			[CONST_SLOT_LEFT] = 16118, -- glacial rod (nivel 65)
			[CONST_SLOT_RIGHT] = 8075,
			[CONST_SLOT_FEET] = 3079,
		},
		mochila = comRunas({ { 3156, 2 }, { 238, 1 }, { 266, 1 } }), -- wild growth, pocoes
	},
	[7] = { -- Royal Paladin: a Ironworker e de duas maos
		vida = 905, mana = 1170, cap = 1910, ml = 22,
		skills = { [SKILL_DISTANCE] = 95, [SKILL_SHIELD] = 75 },
		slots = {
			[CONST_SLOT_HEAD] = 10385, -- zaoan helmet
			[CONST_SLOT_ARMOR] = 8063, -- paladin armor
			[CONST_SLOT_LEGS] = 10387, -- zaoan legs
			[CONST_SLOT_LEFT] = 8025, -- ironworker (nivel 80)
		},
		municao = { 16142, 100 }, -- drill bolt (nivel 70), infinito
		mochila = comRunas({ { 7642, 1 }, { 238, 1 } }), -- great spirit, great mana
	},
	[8] = { -- Elite Knight: melee 95 nas tres armas; o kit leva espada
		vida = 1265, mana = 450, cap = 2270, ml = 10,
		skills = { [SKILL_CLUB] = 95, [SKILL_SWORD] = 95, [SKILL_AXE] = 95, [SKILL_SHIELD] = 90 },
		slots = {
			[CONST_SLOT_HEAD] = 10385, -- zaoan helmet
			[CONST_SLOT_ARMOR] = 10384, -- zaoan armor
			[CONST_SLOT_LEGS] = 10387, -- zaoan legs
			[CONST_SLOT_LEFT] = 3288, -- magic sword (nivel 80)
			[CONST_SLOT_FEET] = 3079, -- boots of haste
		},
		mochila = comRunas({ { 239, 1 }, { 237, 1 } }), -- great health, strong mana
	},
}

local TODAS_AS_SKILLS = { SKILL_FIST, SKILL_CLUB, SKILL_SWORD, SKILL_AXE, SKILL_DISTANCE, SKILL_SHIELD, SKILL_FISHING }

local function molde(player)
	local voc = player:getVocation():getId()
	if voc >= 1 and voc <= 4 then
		voc = voc + 4 -- sem promocao: mesmo molde da promovida
	end
	return MOLDES[voc]
end

local function kv(player)
	return player:kv():scoped("hegemony")
end

local function marcar(item, player)
	if item then
		item:setCustomAttribute(Hegemony.DONO, player:getGuid())
	end
	return item
end

local function darKit(player, m)
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		local item = player:getSlotItem(slot)
		if item then
			item:remove()
		end
	end
	for slot, id in pairs(m.slots) do
		marcar(player:addItem(id, 1, false, 1, slot), player)
	end
	if m.municao then
		-- com 5 argumentos o addItem cria UMA pilha com subType = quantidade
		marcar(player:addItem(m.municao[1], 1, false, m.municao[2], CONST_SLOT_AMMO), player)
	end
	local mochila = player:addItem(2854, 1, false, 1, CONST_SLOT_BACKPACK)
	if mochila then
		for _, e in ipairs(m.mochila) do
			mochila:addItem(e[1], e[2])
		end
	end
end

-- Volta ao molde: nivel 80, vida/mana/cap do 80, ML e skills do molde, kit
-- novo. setLevel so troca nivel e experiencia; o resto e posto aqui.
function Hegemony.renascer(player)
	local m = molde(player)
	if not m then
		return false
	end
	player:setLevel(NIVEL)
	player:setMaxHealth(m.vida)
	player:setMaxMana(m.mana)
	player:setCapacity(m.cap * 100)
	player:setMagicLevel(m.ml)
	for _, skill in ipairs(TODAS_AS_SKILLS) do
		player:setSkillLevel(skill, m.skills[skill] or 10)
	end
	darKit(player, m)
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
	kv(player):remove(KV_RESETAR)
	kv(player):set(KV_NASCEU, true)
	return true
end

local function semNadaEquipado(player)
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		if player:getSlotItem(slot) then
			return false
		end
	end
	return true
end

local morte = CreatureEvent("HegemonyMorte")
function morte.onDeath(player, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	if Hegemony.livre(player) then
		return true
	end
	-- Tudo para o corpo, sem sorteio. O DropLoot do upstream tambem roda
	-- (bencaos, 10% por item equipado); em qualquer ordem o resultado e o
	-- mesmo: o que ele nao mover, este move.
	if corpse and corpse:isContainer() then
		for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
			local item = player:getSlotItem(slot)
			if item then
				item:moveTo(corpse)
			end
		end
	end
	kv(player):set(KV_RESETAR, true)
	return true
end
morte:register()

local entrada = CreatureEvent("HegemonyRenascerLogin")
function entrada.onLogin(player)
	player:registerEvent("HegemonyMorte")
	if Hegemony.livre(player) then
		return true
	end
	if kv(player):get(KV_RESETAR) then
		Hegemony.renascer(player)
	elseif not kv(player):get(KV_NASCEU) then
		-- Personagem novo sai do Sample sem itens; personagem antigo, com os
		-- dele, fica como esta ate a primeira morte.
		if semNadaEquipado(player) then
			Hegemony.renascer(player)
		else
			kv(player):set(KV_NASCEU, true)
		end
	end
	return true
end
entrada:register()

local volta = EventCallback("HegemonyRenascerSpawn")
function volta.playerOnChangeZone(player, zone)
	if not Hegemony.livre(player) and kv(player):get(KV_RESETAR) then
		Hegemony.renascer(player)
	end
end
volta:register()
