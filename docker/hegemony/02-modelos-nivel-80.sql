-- Personagens modelo do Hegemony PvP: todo personagem novo nasce pronto.
-- Idempotente: pode rodar de novo.
--
-- Aplicar com:
--   docker exec -i otbr-db-1 sh -c \
--     'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
--     < docker/hegemony/02-modelos-nivel-80.sql
--   docker restart otbr-myaac-1   # o MyAAC guarda settings em cache
--
-- COMO FUNCIONA
--
-- O MyAAC nao cria personagem do zero: copia de um "Sample" por vocacao
-- (setting core.character_samples, padrao 1..4 = Sorcerer/Druid/Paladin/Knight
-- Sample). Copia vocacao, nivel, experiencia, vida, mana, capacidade, soul, os
-- itens de player_items e — so se core.use_character_sample_skills estiver
-- ligado — as skills. Entao basta deixar os quatro Samples no ponto desejado.
--
-- Os Samples ficam fora do ranking: core.highscores_ids_hidden ja esconde 1..6.
--
-- DECISOES (18/09/2026, com o usuario)
--   nivel 80 como ponto de partida — evolui normalmente depois
--   vocacoes promovidas: MS, ED, RP, EK (sem Monk)
--   skills de personagem treinado tipico do 80
--   kit: ver scripts/hegemony/renascer.lua (18/09: equipamento por vocacao
--        definido com o usuario, mais as runas e pocoes infinitas)
--   suprimentos infinitos: ver docker/hegemony/entrypoint.sh
--
-- NUMEROS
--   experiencia do 80 = 7.915.800, pela formula do proprio motor
--     (Player::getExpForLevel: (((L-6)*L+17)*L-12)/6*100)
--   vida/mana/cap = base do nivel 8 (185/90/470) + 72 niveis * ganho do
--     data/XML/vocations.xml: MS/ED 5/30/10, RP 10/15/20, EK 15/5/25
--   EK com ML 10: o Magic Wall exige ML 9 e o kit e o mesmo para todos.
--
-- Todo item foi conferido no items.xml: existe, e o requisito de nivel e
-- vocacao cabe num personagem 80 da vocacao certa.

-- ---------------------------------------------------------------- atributos

UPDATE `players` SET
	`vocation` = 5, `level` = 80, `experience` = 7915800,
	`health` = 545, `healthmax` = 545, `mana` = 2250, `manamax` = 2250,
	`cap` = 1190, `soul` = 200, `maglevel` = 75, `manaspent` = 0,
	`skill_fist` = 10, `skill_fist_tries` = 0, `skill_club` = 10, `skill_club_tries` = 0,
	`skill_sword` = 10, `skill_sword_tries` = 0, `skill_axe` = 10, `skill_axe_tries` = 0,
	`skill_dist` = 10, `skill_dist_tries` = 0, `skill_shielding` = 25, `skill_shielding_tries` = 0,
	`skill_fishing` = 10, `skill_fishing_tries` = 0
WHERE `name` = 'Sorcerer Sample';

UPDATE `players` SET
	`vocation` = 6, `level` = 80, `experience` = 7915800,
	`health` = 545, `healthmax` = 545, `mana` = 2250, `manamax` = 2250,
	`cap` = 1190, `soul` = 200, `maglevel` = 70, `manaspent` = 0,
	`skill_fist` = 10, `skill_fist_tries` = 0, `skill_club` = 10, `skill_club_tries` = 0,
	`skill_sword` = 10, `skill_sword_tries` = 0, `skill_axe` = 10, `skill_axe_tries` = 0,
	`skill_dist` = 10, `skill_dist_tries` = 0, `skill_shielding` = 25, `skill_shielding_tries` = 0,
	`skill_fishing` = 10, `skill_fishing_tries` = 0
WHERE `name` = 'Druid Sample';

UPDATE `players` SET
	`vocation` = 7, `level` = 80, `experience` = 7915800,
	`health` = 905, `healthmax` = 905, `mana` = 1170, `manamax` = 1170,
	`cap` = 1910, `soul` = 200, `maglevel` = 22, `manaspent` = 0,
	`skill_fist` = 10, `skill_fist_tries` = 0, `skill_club` = 10, `skill_club_tries` = 0,
	`skill_sword` = 10, `skill_sword_tries` = 0, `skill_axe` = 10, `skill_axe_tries` = 0,
	`skill_dist` = 95, `skill_dist_tries` = 0, `skill_shielding` = 75, `skill_shielding_tries` = 0,
	`skill_fishing` = 10, `skill_fishing_tries` = 0
WHERE `name` = 'Paladin Sample';

-- Melee 95 nas tres armas, para o EK usar a que preferir.
UPDATE `players` SET
	`vocation` = 8, `level` = 80, `experience` = 7915800,
	`health` = 1265, `healthmax` = 1265, `mana` = 450, `manamax` = 450,
	`cap` = 2270, `soul` = 200, `maglevel` = 10, `manaspent` = 0,
	`skill_fist` = 10, `skill_fist_tries` = 0, `skill_club` = 95, `skill_club_tries` = 0,
	`skill_sword` = 95, `skill_sword_tries` = 0, `skill_axe` = 95, `skill_axe_tries` = 0,
	`skill_dist` = 10, `skill_dist_tries` = 0, `skill_shielding` = 90, `skill_shielding_tries` = 0,
	`skill_fishing` = 10, `skill_fishing_tries` = 0
WHERE `name` = 'Knight Sample';

-- ---------------------------------------------------------------- itens
--
-- Desde 18/09/2026 o kit NAO mora aqui: e entregue por
-- data-otservbr-global/scripts/hegemony/renascer.lua no primeiro login e de
-- novo a cada morte (morrer derruba tudo e devolve o personagem ao molde).
-- Um kit so, no Lua, para quem nasce e para quem renasce. Os Samples ficam so
-- com a store inbox (pid 11), que todo personagem precisa ter.

SET @ms = (SELECT `id` FROM `players` WHERE `name` = 'Sorcerer Sample');
SET @ed = (SELECT `id` FROM `players` WHERE `name` = 'Druid Sample');
SET @rp = (SELECT `id` FROM `players` WHERE `name` = 'Paladin Sample');
SET @ek = (SELECT `id` FROM `players` WHERE `name` = 'Knight Sample');

DELETE FROM `player_items` WHERE `player_id` IN (@ms, @ed, @rp, @ek);

INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES
	(@ms, 11, 101, 23396, 1, ''),  -- store inbox
	(@ed, 11, 101, 23396, 1, ''),
	(@rp, 11, 101, 23396, 1, ''),
	(@ek, 11, 101, 23396, 1, '');

-- Venore (town 9) e o mundo inteiro do Hegemony: ver scripts/hegemony/venore.lua.
UPDATE `players` SET `town_id` = 9
	WHERE `name` IN ('Sorcerer Sample', 'Druid Sample', 'Paladin Sample', 'Knight Sample');

-- ---------------------------------------------------------------- MyAAC
--
-- Skills: sem isto o MyAAC ignora as do Sample e cria tudo com 10.
-- Cidade: o padrao era 1 = Dawnport Tutorial, a ilha de tutorial. Um
-- personagem 80 nasceria la. 9 = Venore, o mapa inteiro do Hegemony.
-- A tabela nao tem chave unica em (name, key), dai o DELETE antes.

DELETE FROM `myaac_settings`
	WHERE `name` = 'core' AND `key` IN ('use_character_sample_skills', 'character_towns');

INSERT INTO `myaac_settings` (`name`, `key`, `value`) VALUES
	('core', 'use_character_sample_skills', 'true'),
	('core', 'character_towns', '9');
