-- Hegemony PvP: o Dragao de Venore e as almas (objetivo com hora marcada,
-- como o dragao do LoL). Desenho combinado com o usuario em 18-19/09/2026.
--
-- O DRAGAO nasce num cruzamento do pantano (andar 7, ao sul do templo, varios
-- acessos) a cada CONFIG.INTERVALO depois de morrer, com aviso para todos 1 min
-- antes. Anda atras de quem estiver perto, mas preso ao covil: uma zona de
-- CONFIG.COLEIRA passos em volta dele que so o dragao nao pode deixar (a mesma
-- trava que prende os jogadores em Venore). Quem fica fora apanha de longe,
-- mas nao arrasta o dragao pela cidade. A primeira versao teleportava de volta
-- e curava; medido: quem parava logo depois do limite fazia o dragao ir e
-- voltar a cada 2 s, curado. Sem apanhar por CONFIG.CALMA segundos, recupera
-- vida. Morre de qualquer ataque, e a alma e de quem der o ultimo golpe. Quem
-- causou ao menos 10% do dano leva ouro.
--
-- A RUNA DO CACADOR e a vantagem comprada para roubar o dragao: carga unica,
-- vendida pelo Varg, tira um dano fixo bem maior que a SD (so no dragao) e so
-- alcanca 2 passos, entao quem tenta o roubo tem que entrar na briga. E a runa
-- verde e fina (17112, sem magia nem outro uso no servidor, e diferente de
-- toda runa dos kits na mochila) com marca de compra (action id). A runa em
-- branco nao serviu: o motor so deixa usar em alvo item "multiuse", e ela nao
-- e.
--
-- AS ALMAS dao +4% de dano em jogador cada, no maximo 3, e seguram o jogo com:
--   - validade de 10 min, que so renova matando alguem (nao escondido);
--   - quem tem 3 nao ganha alma do dragao (o lider nao farma o objetivo);
--   - quem mata o dono de almas rouba 1 e leva 5 mil de ouro por alma dele;
--   - com 3 almas, a posicao do dono e anunciada a cada minuto;
--   - morrer ou deslogar zera (a regra do Hegemony para tudo);
--   - quem carrega alma tem uma aura de brasa em volta (efeito anexado 100, e
--     101 maior com 3 almas; o desenho mora no cliente, game_attachedeffects).
-- Abaixo de ~29% de bonus nenhum mago morre com 2 SDs em vez de 3 (SD em
-- jogador mediu 187-211 contra 545 de vida): o bonus decide luta parelha, nao
-- 2 contra 1.
--
-- MEDIR: cada dragao e cada morte em PvP saem no log do servidor com o prefixo
-- [Hegemony][dragao] / [Hegemony][almas] (docker logs otbr-server-1). Metas:
-- dono de 3 almas vencendo ~55-60% dos 1 contra 1; alma durando 3-6 min; dragao
-- disputado (2+ por perto) em mais da metade das vezes. Ajustar so a CONFIG.

Hegemony = Hegemony or {}

local CONFIG = {
	NOME = "Dragao de Venore",
	COVIL = Position(32958, 32093, 7),
	PRIMEIRO = 3 * 60, -- s depois do boot ate o primeiro dragao
	INTERVALO = 5 * 60, -- s entre a morte de um e o proximo
	AVISO = 60, -- s de antecedencia do aviso
	VIDA = 8000, -- SD em monstro tira ~400 (em jogador o Tibia corta pela metade)
	VELOCIDADE = 120, -- jogador anda a 209: da para fugir dele
	COLEIRA = 6, -- raio da zona do covil, que o dragao nao deixa
	CALMA = 6, -- s sem apanhar ate comecar a se curar
	REGENERACAO = 0.10, -- fracao da vida curada a cada 2 s de calma
	RUNA_ID = 17112, -- runa verde e fina...
	RUNA_AID = 64702, -- ...com esta marca, posta pelo Varg na venda
	RUNA_SPELL_ID = 299,
	RUNA_DANO = 1500, -- ~4 SDs de uma vez: o roubo
	RUNA_ALCANCE = 2,
	RUNA_PRECO = 5000,
	PARTICIPACAO_MIN = 0.10, -- fracao da vida para contar como participante
	OURO_PARTICIPACAO = 2000,
	BONUS_POR_ALMA = 0.04,
	MAX_ALMAS = 3,
	VALIDADE = 10 * 60,
	OURO_POR_ALMA = 5000,
	AVISO_PORTADOR = 60, -- s entre os anuncios de quem tem o maximo
	AURA = 100, -- efeito anexado com 1 ou 2 almas
	AURA_MAXIMA = 101, -- e com o maximo
}

-- O Varg (receptador.lua) vende a runa com estes dados.
Hegemony.RUNA_DO_CACADOR = {
	id = CONFIG.RUNA_ID,
	aid = CONFIG.RUNA_AID,
	preco = CONFIG.RUNA_PRECO,
	nome = "runa do cacador",
	descricao = string.format("Carga unica. Tira %d do Dragao de Venore, a ate %d passos. So fere o dragao.", CONFIG.RUNA_DANO, CONFIG.RUNA_ALCANCE),
}

local function log(prefixo, formato, ...)
	logger.info("[Hegemony][" .. prefixo .. "] " .. formato, ...)
end

local function avisarTodos(texto)
	Game.broadcastMessage(texto, MESSAGE_EVENT_ADVANCE)
end

-- Jogador por tras de um atacante (o proprio, ou o dono do invocado).
local function jogadorDe(criatura)
	if not criatura then
		return nil
	end
	local jogador = criatura:getPlayer()
	if jogador then
		return jogador
	end
	local mestre = criatura:getMaster()
	return mestre and mestre:getPlayer() or nil
end

---------------------------------------------------------------- o monstro

local mType = Game.createMonsterType(CONFIG.NOME)
local dragao = {}
dragao.description = "o Dragao de Venore"
dragao.experience = 0 -- nivel e experiencia sao da luta entre jogadores
dragao.outfit = { lookType = 39, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookAddons = 0, lookMount = 0 }
dragao.health = CONFIG.VIDA
dragao.maxHealth = CONFIG.VIDA
dragao.race = "blood"
-- Sem corpo: o custom_monster_loot.lua do Canary da "christmas tokens" a todo
-- monstro (exemplo que veio de fabrica), e o saque aparecia no dragao.
dragao.corpse = 0
dragao.speed = CONFIG.VELOCIDADE
dragao.manaCost = 0
dragao.changeTarget = { interval = 4000, chance = 20 }
dragao.strategiesTarget = { nearest = 70, random = 30 }
dragao.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}
dragao.light = { level = 4, color = 206 }
dragao.voices = {
	interval = 5000,
	chance = 10,
	{ text = "QUEM VAI SANGRAR POR MIM?", yell = true },
	{ text = "ZCHHHHHHH", yell = true },
}
dragao.loot = {}
-- Ameaca, nao parede: um mago de 545 aguenta alguns turnos com pocao (medido:
-- 40-90 por golpe), o que deixa o roubo de perto arriscado sem ser suicida.
dragao.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -100 },
	{ name = "combat", interval = 2000, chance = 25, type = COMBAT_FIREDAMAGE, minDamage = -40, maxDamage = -100, range = 7, radius = 3, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA, target = true },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_FIREDAMAGE, minDamage = -40, maxDamage = -120, length = 7, spread = 3, effect = CONST_ME_FIREAREA, target = false },
}
dragao.defenses = { defense = 20, armor = 20 }
dragao.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
	{ type = COMBAT_FIREDAMAGE, percent = 100 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 0 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 0 },
}
dragao.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}
mType:register(dragao)

---------------------------------------------------------------- as almas

-- Na memoria, por GUID: morrer, deslogar ou reiniciar o servidor zera.
local almas = {}

local function almasDe(jogador)
	local a = almas[jogador:getGuid()]
	return a and a.n or 0
end
Hegemony.almasDe = almasDe

local function avisarAlmas(jogador)
	local n = almasDe(jogador)
	if n == 0 then
		jogador:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Suas almas do dragao se foram.")
		return
	end
	jogador:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
		"Voce carrega %d alma%s do dragao: +%d%% de dano em jogadores. Somem em %d min sem uma morte sua.",
		n, n > 1 and "s" or "", math.floor(n * CONFIG.BONUS_POR_ALMA * 100 + 0.5), math.floor(CONFIG.VALIDADE / 60)))
end

-- A aura acompanha as almas: some, aparece ou cresce a cada mudanca.
local function atualizarAura(jogador)
	jogador:detachEffectById(CONFIG.AURA)
	jogador:detachEffectById(CONFIG.AURA_MAXIMA)
	local n = almasDe(jogador)
	if n > 0 then
		jogador:attachEffectById(n >= CONFIG.MAX_ALMAS and CONFIG.AURA_MAXIMA or CONFIG.AURA, false)
	end
end

local function darAlma(jogador, origem)
	local guid = jogador:getGuid()
	local a = almas[guid] or { n = 0 }
	if a.n >= CONFIG.MAX_ALMAS then
		return false
	end
	a.n = a.n + 1
	a.expira = os.time() + CONFIG.VALIDADE
	a.anuncio = 0
	almas[guid] = a
	atualizarAura(jogador)
	avisarAlmas(jogador)
	log("almas", "{} ganhou alma ({}), agora {}", jogador:getName(), origem, a.n)
	return true
end

local function renovarAlmas(jogador)
	local a = almas[jogador:getGuid()]
	if a then
		a.expira = os.time() + CONFIG.VALIDADE
	end
end

local function zerarAlmas(jogador, motivo)
	local a = almas[jogador:getGuid()]
	if a then
		almas[jogador:getGuid()] = nil
		atualizarAura(jogador)
		log("almas", "{} perdeu {} alma(s) ({})", jogador:getName(), a.n, motivo)
	end
end

local function multiplicador(jogador)
	return 1 + almasDe(jogador) * CONFIG.BONUS_POR_ALMA
end

-- Dano de quem tem alma em outro jogador: registrado na VITIMA, com o
-- atacante vindo como parametro. Vida e mana (utamo vita), senao o bonus sumia
-- contra mago de escudo.
local function aplicarBonus(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if primaryType ~= COMBAT_HEALING then
		local dono = jogadorDe(attacker)
		if dono and dono ~= creature and almasDe(dono) > 0 then
			local m = multiplicador(dono)
			primaryDamage = math.floor(primaryDamage * m)
			secondaryDamage = math.floor(secondaryDamage * m)
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

local bonusVida = CreatureEvent("HegemonyAlmasVida")
function bonusVida.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	return aplicarBonus(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)
end
bonusVida:register()

local bonusMana = CreatureEvent("HegemonyAlmasMana")
function bonusMana.onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	return aplicarBonus(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)
end
bonusMana:register()

-- Morte em PvP: rouba alma, paga a cabeca, renova quem matou, zera quem morreu.
local mortePvp = CreatureEvent("HegemonyAlmasMorte")
function mortePvp.onDeath(player, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local vitima = player:getPlayer()
	if not vitima then
		return true
	end
	local matador = jogadorDe(killer) or jogadorDe(mostDamageKiller)
	local nVitima = almasDe(vitima)
	if matador and matador ~= vitima then
		log("almas", "PvP: {} ({} almas) matou {} ({} almas)", matador:getName(), almasDe(matador), vitima:getName(), nVitima)
		if nVitima > 0 then
			local ouro = nVitima * CONFIG.OURO_POR_ALMA
			matador:addMoney(ouro)
			if not darAlma(matador, "roubada de " .. vitima:getName()) then
				renovarAlmas(matador)
			end
			avisarTodos(string.format("%s derrubou %s e tomou uma alma do dragao (+%d de ouro).", matador:getName(), vitima:getName(), ouro))
		else
			renovarAlmas(matador)
		end
	end
	zerarAlmas(vitima, "morreu")
	return true
end
mortePvp:register()

local entrada = CreatureEvent("HegemonyAlmasEntrada")
function entrada.onLogin(player)
	player:registerEvent("HegemonyAlmasVida")
	player:registerEvent("HegemonyAlmasMana")
	player:registerEvent("HegemonyAlmasMorte")
	zerarAlmas(player, "entrou")
	return true
end
entrada:register()

local saida = CreatureEvent("HegemonyAlmasSaida")
function saida.onLogout(player)
	zerarAlmas(player, "saiu")
	return true
end
saida:register()

-- Direcao como no exiva, para anunciar o dono de almas a cada um.
local function direcao(de, para)
	local dx, dy = para.x - de.x, para.y - de.y
	local dist = math.max(math.abs(dx), math.abs(dy))
	local andar = ""
	if para.z < de.z then
		andar = ", num andar acima"
	elseif para.z > de.z then
		andar = ", num andar abaixo"
	end
	if dist <= 4 then
		return "bem perto de voce" .. andar
	end
	local nomes = { [0] = "leste", "sudeste", "sul", "sudoeste", "oeste", "noroeste", "norte", "nordeste" }
	local setor = math.floor((math.deg(math.atan2(dy, dx)) + 22.5) % 360 / 45)
	return (dist <= 25 and "perto, a " or "longe, a ") .. nomes[setor] .. andar
end

---------------------------------------------------------------- o covil

local estado = {
	proximo = os.time() + CONFIG.PRIMEIRO,
	avisado = false,
	id = nil, -- creature id do dragao vivo
	nasceu = 0,
	ultimoDano = 0,
	dano = {}, -- nome do jogador -> dano causado
}

local function dragaoVivo()
	return estado.id and Monster(estado.id) or nil
end

-- So conta quem bateu, para o ouro de participacao; o dano passa inteiro.
local vidaDragao = CreatureEvent("HegemonyDragaoVida")
function vidaDragao.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	local jogador = jogadorDe(attacker)
	if jogador and primaryType ~= COMBAT_HEALING then
		local nome = jogador:getName()
		local total = math.min(creature:getHealth(), math.abs(primaryDamage) + math.abs(secondaryDamage))
		estado.dano[nome] = (estado.dano[nome] or 0) + total
		estado.ultimoDano = os.time()
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
vidaDragao:register()

local morteDragao = CreatureEvent("HegemonyDragaoMorte")
function morteDragao.onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local vencedor = jogadorDe(killer)
	local tempo = os.time() - estado.nasceu
	creature:getPosition():sendMagicEffect(CONST_ME_FIREAREA)
	local participantes = {}
	for nome, dano in pairs(estado.dano) do
		participantes[#participantes + 1] = string.format("%s=%d", nome, dano)
		if dano >= CONFIG.VIDA * CONFIG.PARTICIPACAO_MIN then
			local p = Player(nome)
			if p then
				p:addMoney(CONFIG.OURO_PARTICIPACAO)
				p:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Voce ajudou a derrubar o dragao: +%d de ouro.", CONFIG.OURO_PARTICIPACAO))
			end
		end
	end
	log("dragao", "morto por {} em {}s; dano: {}", vencedor and vencedor:getName() or "?", tempo, table.concat(participantes, " "))
	if vencedor then
		if darAlma(vencedor, "dragao") then
			avisarTodos(string.format("%s derrubou o Dragao de Venore e tomou uma alma!", vencedor:getName()))
		else
			renovarAlmas(vencedor)
			avisarTodos(string.format("%s derrubou o Dragao de Venore, mas ja carrega o maximo de almas.", vencedor:getName()))
		end
	end
	estado.id = nil
	estado.proximo = os.time() + CONFIG.INTERVALO
	estado.avisado = false
	return true
end
morteDragao:register()

-- A coleira: so o dragao nao sai da zona do covil. O ZoneEvent devolve o
-- retorno direto ao motor e nil BLOQUEIA: sempre retornar algo (ver venore.lua).
local covil = Zone("hegemony.covil")
covil:addArea(Position(CONFIG.COVIL.x - CONFIG.COLEIRA, CONFIG.COVIL.y - CONFIG.COLEIRA, CONFIG.COVIL.z), Position(CONFIG.COVIL.x + CONFIG.COLEIRA, CONFIG.COVIL.y + CONFIG.COLEIRA, CONFIG.COVIL.z))
local coleira = ZoneEvent(covil)
function coleira.beforeLeave(zone, creature)
	return not (estado.id ~= nil and creature:getId() == estado.id)
end
coleira:register()

-- A cada 2 s enquanto o dragao vive: cura sem apanhar. Largado ate encher, o
-- dano de quem bateu deixa de contar (a luta recomeca do zero).
local function cuidarDoDragao()
	local m = dragaoVivo()
	if not m then
		return
	end
	local pos = m:getPosition()
	if os.time() - estado.ultimoDano >= CONFIG.CALMA and m:getHealth() < m:getMaxHealth() then
		m:addHealth(math.floor(m:getMaxHealth() * CONFIG.REGENERACAO))
		pos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		if m:getHealth() >= m:getMaxHealth() then
			estado.dano = {}
		end
	end
	addEvent(cuidarDoDragao, 2000)
end

local function nascer()
	local m = Game.createMonster(CONFIG.NOME, CONFIG.COVIL, true, true)
	if not m then
		log("dragao", "nao consegui criar o dragao em {},{},{}", CONFIG.COVIL.x, CONFIG.COVIL.y, CONFIG.COVIL.z)
		estado.proximo = os.time() + 60
		return
	end
	m:registerEvent("HegemonyDragaoVida")
	m:registerEvent("HegemonyDragaoMorte")
	estado.id = m:getId()
	estado.nasceu = os.time()
	estado.ultimoDano = os.time()
	estado.dano = {}
	addEvent(cuidarDoDragao, 2000)
	CONFIG.COVIL:sendMagicEffect(CONST_ME_FIREAREA)
	avisarTodos("O Dragao de Venore despertou no pantano, ao sul do templo!")
	log("dragao", "nasceu")
end

-- Um relogio para o dragao e para as almas.
local relogio = GlobalEvent("HegemonyDragaoRelogio")
function relogio.onThink(interval)
	local agora = os.time()
	if not dragaoVivo() then
		estado.id = nil
		if not estado.avisado and agora >= estado.proximo - CONFIG.AVISO then
			estado.avisado = true
			avisarTodos("O Dragao de Venore desperta em 1 minuto no pantano, ao sul do templo.")
		end
		if agora >= estado.proximo then
			nascer()
		end
	end

	-- Almas: validade, e brilho e anuncio de quem tem o maximo.
	for _, p in ipairs(Game.getPlayers()) do
		local a = almas[p:getGuid()]
		if a then
			if agora >= a.expira then
				zerarAlmas(p, "expirou")
				avisarAlmas(p)
			else
				if a.n >= CONFIG.MAX_ALMAS then
					p:getPosition():sendMagicEffect(CONST_ME_FIREAREA)
				end
				if a.n >= CONFIG.MAX_ALMAS and agora - (a.anuncio or 0) >= CONFIG.AVISO_PORTADOR then
					a.anuncio = agora
					for _, outro in ipairs(Game.getPlayers()) do
						if outro ~= p then
							outro:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("%s carrega %d almas do dragao e esta %s.", p:getName(), a.n, direcao(outro:getPosition(), p:getPosition())))
						end
					end
				end
			end
		end
	end
	return true
end
relogio:interval(10 * 1000)
relogio:register()

---------------------------------------------------------------- a runa

-- A runa comprada (com a marca) que o jogador carrega, se houver.
local function runaComprada(jogador)
	local function marcada(item)
		return item:getId() == CONFIG.RUNA_ID and item:getActionId() == CONFIG.RUNA_AID
	end
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		local item = jogador:getSlotItem(slot)
		if item then
			if marcada(item) then
				return item
			end
			if item:isContainer() then
				for _, dentro in ipairs(item:getItems(true)) do
					if marcada(dentro) then
						return dentro
					end
				end
			end
		end
	end
end

-- Quando a magia falha o motor manda "You cannot use this object." por cima
-- da mensagem do script; a nossa vai logo depois, para ficar a que se le.
local function recusar(jogador, texto)
	addEvent(function(cid)
		local p = Player(cid)
		if p then
			p:sendCancelMessage(texto)
		end
	end, 100, jogador:getId())
	return false
end

local runa = Spell("rune")
function runa.onCastSpell(creature, variant, isHotkey)
	local jogador = creature:getPlayer()
	if not jogador then
		return false
	end
	-- Pelo id da criatura: o motor capitaliza o nome ("Dragao De Venore").
	local alvo = Creature(variant:getNumber())
	if not alvo or not estado.id or alvo:getId() ~= estado.id then
		return recusar(jogador, "A Runa do Cacador so fere o Dragao de Venore.")
	end
	local de, para = jogador:getPosition(), alvo:getPosition()
	if de.z ~= para.z or de:getDistanceBetween(para) > CONFIG.RUNA_ALCANCE or not de:isSightClear(para) then
		return recusar(jogador, string.format("Chegue mais perto: a Runa do Cacador so alcanca %d passos.", CONFIG.RUNA_ALCANCE))
	end
	local comprada = runaComprada(jogador)
	if not comprada then
		return recusar(jogador, "Essa runa nao tem forca. A Runa do Cacador de verdade se compra com o Varg.")
	end
	doTargetCombatHealth(jogador, alvo, COMBAT_HOLYDAMAGE, -CONFIG.RUNA_DANO, -CONFIG.RUNA_DANO, CONST_ME_HOLYAREA)
	comprada:remove(1) -- carga unica, mesmo com as runas infinitas do servidor
	log("dragao", "{} usou a Runa do Cacador", jogador:getName())
	return true
end
runa:id(CONFIG.RUNA_SPELL_ID)
runa:group("attack")
runa:name("runa do cacador")
runa:runeId(CONFIG.RUNA_ID)
runa:allowFarUse(true)
runa:charges(1)
runa:level(0) -- com nivel > 0 o "look" mostra as palavras da runa, que ela nao tem
runa:magicLevel(0)
runa:cooldown(2 * 1000)
runa:groupCooldown(2 * 1000)
runa:needTarget(true)
runa:isBlocking(true)
runa:register()
