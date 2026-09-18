local mountIds = { 22, 25, 26 }

local rentedMounts = GlobalEvent("rentedmounts")
function rentedMounts.onThink(interval)
	local players = Game.getPlayers()
	if #players == 0 then
		return true
	end

	local player, outfit, expiraEm
	for i = 1, #players do
		player = players[i]
		expiraEm = player:getStorageValue(Storage.Quest.U9_1.HorseStationWorldChange.Timer)

		-- A condicao esta invertida de proposito. Antes havia um `break` quando
		-- o aluguel NAO tinha vencido, o que abandonava o laco no primeiro
		-- jogador sem cavalo alugado — o caso comum, storage < 1. Efeito: com
		-- qualquer jogador assim na frente da lista, aluguel nenhum expirava.
		-- Lua nao tem `continue`, entao a correcao e processar so quem venceu.
		if expiraEm >= 1 and expiraEm < os.time() then
			outfit = player:getOutfit()
			if table.contains(mountIds, outfit.lookMount) then
				outfit.lookMount = nil
				player:setOutfit(outfit)
			end

			for m = 1, #mountIds do
				player:removeMount(mountIds[m])
			end

			player:setStorageValue(Storage.Quest.U9_1.HorseStationWorldChange.Timer, -1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your contract with your horse expired and it returned back to the horse station.")
		end
	end
	return true
end

rentedMounts:interval(15000)
rentedMounts:register()
