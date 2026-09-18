-- Hegemony PvP: desativado. O receptador (Varg) e o unico que vende, e no
-- Hegemony tudo cai no corpo ao morrer, com ou sem amulet of loss: comprar um
-- seria jogar 50.000 fora. Arquivo montado pelo docker/docker-compose.yml.
local aol = TalkAction("!aol")

function aol.onSay(player, words, param)
	player:sendCancelMessage("No Hegemony tudo cai ao morrer: amulet of loss nao protege nada e ninguem vende.")
	return true
end

aol:groupType("normal")
aol:register()
