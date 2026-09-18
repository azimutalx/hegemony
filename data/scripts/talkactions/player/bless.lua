-- Hegemony PvP: desativado. Bencao reduz a experiencia que a vitima perde, e
-- o ganho de quem mata sai exatamente dessa perda (Player::getGainedExperience):
-- abencoar-se viraria forma de negar experiencia ao assassino. O receptador
-- (Varg) e o unico que vende. Arquivo montado pelo docker/docker-compose.yml.
local bless = TalkAction("!bless")

function bless.onSay(player, words, param)
	player:sendCancelMessage("No Hegemony nao ha bencaos: quem te derrubar leva a experiencia inteira.")
	return true
end

bless:groupType("normal")
bless:register()
