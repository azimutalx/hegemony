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
--   kit: Magic Wall, Disintegrate, Destroy Field, Fire Bomb, pocoes;
--        Wild Growth so para o ED (a rune e restrita a druida)
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
-- pid 1..11 = slot do corpo (1 cabeca, 2 colar, 3 mochila, 4 armadura,
-- 5 escudo, 6 arma, 7 pernas, 8 pes, 10 municao, 11 store inbox).
-- Conteudo da mochila usa como pid o sid da mochila (103).
-- Para rune, `count` e a carga; com carga infinita ela nunca desce.

SET @ms = (SELECT `id` FROM `players` WHERE `name` = 'Sorcerer Sample');
SET @ed = (SELECT `id` FROM `players` WHERE `name` = 'Druid Sample');
SET @rp = (SELECT `id` FROM `players` WHERE `name` = 'Paladin Sample');
SET @ek = (SELECT `id` FROM `players` WHERE `name` = 'Knight Sample');

DELETE FROM `player_items` WHERE `player_id` IN (@ms, @ed, @rp, @ek);

INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES
	-- Master Sorcerer
	(@ms,   1, 101,  3210, 1, ''),  -- hat of the mad
	(@ms,   2, 102,  3055, 1, ''),  -- platinum amulet
	(@ms,   3, 103,  2854, 1, ''),  -- backpack
	(@ms,   4, 104,  3567, 1, ''),  -- blue robe
	(@ms,   5, 105,  8074, 1, ''),  -- spellbook of mind control (nivel 50)
	(@ms,   6, 106,  8092, 1, ''),  -- wand of starstorm (nivel 37)
	(@ms,   7, 107,   645, 1, ''),  -- blue legs
	(@ms,   8, 108,  3079, 1, ''),  -- boots of haste
	(@ms,  11, 109, 23396, 1, ''),  -- store inbox
	(@ms, 103, 110,  3180, 3, ''),  -- magic wall rune
	(@ms, 103, 111,  3197, 3, ''),  -- disintegrate rune
	(@ms, 103, 112,  3148, 3, ''),  -- destroy field rune
	(@ms, 103, 113,  3192, 2, ''),  -- fire bomb rune
	(@ms, 103, 114,   238, 1, ''),  -- great mana potion
	(@ms, 103, 115,   266, 1, ''),  -- health potion (mago nao bebe as fortes)

	-- Elder Druid
	(@ed,   1, 101,  3210, 1, ''),  -- hat of the mad
	(@ed,   2, 102,  3055, 1, ''),  -- platinum amulet
	(@ed,   3, 103,  2854, 1, ''),  -- backpack
	(@ed,   4, 104,  3567, 1, ''),  -- blue robe
	(@ed,   5, 105,  8074, 1, ''),  -- spellbook of mind control
	(@ed,   6, 106,  8082, 1, ''),  -- underworld rod (nivel 42)
	(@ed,   7, 107,   645, 1, ''),  -- blue legs
	(@ed,   8, 108,  3079, 1, ''),  -- boots of haste
	(@ed,  11, 109, 23396, 1, ''),  -- store inbox
	(@ed, 103, 110,  3180, 3, ''),  -- magic wall rune
	(@ed, 103, 111,  3156, 2, ''),  -- wild growth rune (so druida)
	(@ed, 103, 112,  3197, 3, ''),  -- disintegrate rune
	(@ed, 103, 113,  3148, 3, ''),  -- destroy field rune
	(@ed, 103, 114,  3192, 2, ''),  -- fire bomb rune
	(@ed, 103, 115,   238, 1, ''),  -- great mana potion
	(@ed, 103, 116,   266, 1, ''),  -- health potion

	-- Royal Paladin (arbalest e de duas maos: sem escudo)
	(@rp,   1, 101,  3392, 1, ''),  -- royal helmet
	(@rp,   2, 102,  3055, 1, ''),  -- platinum amulet
	(@rp,   3, 103,  2854, 1, ''),  -- backpack
	(@rp,   4, 104,  3381, 1, ''),  -- crown armor
	(@rp,   6, 106,  5803, 1, ''),  -- arbalest (nivel 75)
	(@rp,   7, 107,  3382, 1, ''),  -- crown legs
	(@rp,   8, 108,  3079, 1, ''),  -- boots of haste
	(@rp,  10, 109,  3450, 1, ''),  -- power bolt (nivel 55), infinito
	(@rp,  11, 110, 23396, 1, ''),  -- store inbox
	(@rp, 103, 111,  3180, 3, ''),  -- magic wall rune
	(@rp, 103, 112,  3197, 3, ''),  -- disintegrate rune
	(@rp, 103, 113,  3148, 3, ''),  -- destroy field rune
	(@rp, 103, 114,  3192, 2, ''),  -- fire bomb rune
	(@rp, 103, 115,  7642, 1, ''),  -- great spirit potion
	(@rp, 103, 116,   238, 1, ''),  -- great mana potion

	-- Elite Knight
	(@ek,   1, 101,  3392, 1, ''),  -- royal helmet
	(@ek,   2, 102,  3055, 1, ''),  -- platinum amulet
	(@ek,   3, 103,  2854, 1, ''),  -- backpack
	(@ek,   4, 104,  3366, 1, ''),  -- magic plate armor
	(@ek,   5, 105,  3414, 1, ''),  -- mastermind shield
	(@ek,   6, 106,  3320, 1, ''),  -- fire axe (nivel 35)
	(@ek,   7, 107,  3382, 1, ''),  -- crown legs
	(@ek,   8, 108,  3554, 1, ''),  -- steel boots
	(@ek,  11, 109, 23396, 1, ''),  -- store inbox
	(@ek, 103, 110,  3180, 3, ''),  -- magic wall rune
	(@ek, 103, 111,  3197, 3, ''),  -- disintegrate rune
	(@ek, 103, 112,  3148, 3, ''),  -- destroy field rune
	(@ek, 103, 113,  3192, 2, ''),  -- fire bomb rune
	(@ek, 103, 114,   239, 1, ''),  -- great health potion
	(@ek, 103, 115,   237, 1, '');  -- strong mana potion

-- ---------------------------------------------------------------- MyAAC
--
-- Skills: sem isto o MyAAC ignora as do Sample e cria tudo com 10.
-- Cidade: o padrao era 1 = Dawnport Tutorial, a ilha de tutorial. Um
-- personagem 80 nasceria la. 8 = Thais, a mesma cidade dos Samples.
-- A tabela nao tem chave unica em (name, key), dai o DELETE antes.

DELETE FROM `myaac_settings`
	WHERE `name` = 'core' AND `key` IN ('use_character_sample_skills', 'character_towns');

INSERT INTO `myaac_settings` (`name`, `key`, `value`) VALUES
	('core', 'use_character_sample_skills', 'true'),
	('core', 'character_towns', '8');
