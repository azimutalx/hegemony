-- Hegemony PvP: avisa quem joga com cliente sem atualizador.
--
-- O cliente com atualizador (hegemony-client, modules/hegemony_atualizador)
-- manda a versao dele pelo opcode estendido 90 assim que entra no jogo. Quem
-- nao mandou nada em ESPERA ms roda um pacote de antes do atualizador, que nao
-- sabe se atualizar sozinho: recebe uma janela com o link do cliente novo.
-- Depois dessa baixada, as proximas atualizacoes chegam sozinhas ao abrir.

local OPCODE_VERSAO = 90
local ESPERA = 6000

local versoes = {} -- guid -> versao que o cliente informou nesta sessao

local function linkDoCliente()
	local ip = configManager and configKeys and configKeys.IP and configManager.getString(configKeys.IP)
	if ip and ip ~= "" and ip ~= "127.0.0.1" then
		return string.format("http://%s/cliente/Hegemony.zip", ip)
	end
	return "a pagina Baixar o cliente do site"
end

local opcode = CreatureEvent("HegemonyVersaoCliente")
function opcode.onExtendedOpcode(player, op, buffer)
	if op == OPCODE_VERSAO then
		versoes[player:getGuid()] = buffer
		logger.info("[Hegemony][cliente] {} usa o cliente {}", player:getName(), buffer)
	end
end
opcode:register()

local entrada = CreatureEvent("HegemonyVersaoEntrada")
function entrada.onLogin(player)
	player:registerEvent("HegemonyVersaoCliente")
	local guid = player:getGuid()
	versoes[guid] = nil
	addEvent(function(cid)
		local p = Player(cid)
		if not p or versoes[guid] then
			return
		end
		local janela = ModalWindow({
			title = "Cliente desatualizado",
			message = "Seu cliente e de antes do atualizador automatico e nao recebe as novidades.\n\n"
				.. "Baixe o novo em " .. linkDoCliente() .. " e extraia por cima da pasta do jogo (pode substituir tudo).\n\n"
				.. "E so desta vez: depois disso, as atualizacoes chegam sozinhas quando voce abre o cliente.",
		})
		janela:addButton("OK")
		janela:setDefaultEnterButton(0)
		janela:setDefaultEscapeButton(0)
		janela:sendToPlayer(p)
		logger.info("[Hegemony][cliente] {} entrou com cliente sem atualizador: avisado", p:getName())
	end, ESPERA, player:getId())
	return true
end
entrada:register()

local saida = CreatureEvent("HegemonyVersaoSaida")
function saida.onLogout(player)
	versoes[player:getGuid()] = nil
	return true
end
saida:register()
