-- Hegemony PvP: toda conta nova ja nasce com cinco personagens.
-- Idempotente: pode rodar de novo.
--
-- Aplicar com:
--   docker exec -i otbr-db-1 sh -c \
--     'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
--     < docker/hegemony/03-contas-com-personagens.sql
--   docker restart otbr-myaac-1   # o MyAAC guarda settings em cache
--
-- DECISAO (18/09/2026, com o usuario): ao criar a conta o jogador ja recebe
-- uma lista de personagens, um de cada vocacao, com nome aleatorio. Os EK sao
-- dois: um com Magic Sword e escudo, outro com Avenger (de duas maos). O
-- jogador escolhe na lista com qual joga.
--
-- POR QUE NO BANCO E NAO NO SITE: um gatilho em `accounts` vale para qualquer
-- caminho de cadastro (formulario do MyAAC, painel, script). O site so
-- precisa parar de criar o personagem dele no mesmo formulario
-- (account_create_character_create, no fim deste arquivo), senao seriam seis.
--
-- COMO: cada personagem e uma copia do Sample da vocacao (nivel 80, skills,
-- vida/mana; ver 02-modelos-nivel-80.sql), feita por tabela temporaria para
-- nao depender da lista de colunas de `players`, que muda com o Canary e com
-- o MyAAC. Sai sem itens (so a store inbox): o kit e entregue no primeiro
-- login por data-otservbr-global/scripts/hegemony/renascer.lua. O EK da
-- Avenger leva a storage 98700 = 1 (Hegemony.STORAGE_EK_AVENGER no Lua).
--
-- Roupa: a tipica de cada vocacao, e a do EK da Avenger e a de barbaro, para
-- os dois cavaleiros se distinguirem na lista. Sexo sorteado; a roupa segue o
-- sexo (Canary: 0 = feminino, 1 = masculino).
--
-- Contas de staff (type >= 4) nao recebem nada.

DROP TRIGGER IF EXISTS `hegemony_conta_nova`;
DROP PROCEDURE IF EXISTS `hegemony_criar_personagens`;
DROP FUNCTION IF EXISTS `hegemony_nome`;

DELIMITER $$

-- Nome de fantasia: prefixo + ligacao + final. Final que comeca com vogal so
-- recebe ligacao de consoante, e vice-versa: sem "Iruion" nem "Branuius".
-- 32 x (7 x 11 + 5 x 14) = 4.704 nomes; so letras, primeira maiuscula.
CREATE FUNCTION `hegemony_nome`() RETURNS VARCHAR(30) NOT DETERMINISTIC NO SQL
BEGIN
	DECLARE prefixo VARCHAR(10) DEFAULT ELT(1 + FLOOR(RAND() * 32),
		'Ar', 'Bel', 'Cor', 'Dar', 'El', 'Fen', 'Gor', 'Hal', 'Ir', 'Jor', 'Kal', 'Lor',
		'Mor', 'Nar', 'Ost', 'Pyr', 'Quel', 'Ral', 'Sar', 'Tor', 'Ul', 'Var', 'Wyn', 'Xan',
		'Yor', 'Zar', 'Thal', 'Vex', 'Kael', 'Dor', 'Bran', 'Ceth');
	IF RAND() < 0.5 THEN
		RETURN CONCAT(prefixo,
			ELT(1 + FLOOR(RAND() * 7), '', 'r', 'n', 'l', 'd', 'th', 'v'),
			ELT(1 + FLOOR(RAND() * 11), 'ion', 'ius', 'os', 'ak', 'en', 'eth', 'ir', 'on', 'us', 'yn', 'ar'));
	END IF;
	RETURN CONCAT(prefixo,
		ELT(1 + FLOOR(RAND() * 5), '', 'a', 'e', 'i', 'o'),
		ELT(1 + FLOOR(RAND() * 14),
			'ric', 'dan', 'mir', 'las', 'gar', 'ven', 'dor', 'rim', 'wen', 'lith', 'var', 'dal', 'nor', 'thas'));
END$$

CREATE PROCEDURE `hegemony_criar_personagens`(IN `conta` INT)
BEGIN
	DECLARE i INT DEFAULT 0;
	DECLARE amostra VARCHAR(30);
	DECLARE nome VARCHAR(60);
	DECLARE sexo INT;
	DECLARE novo INT;
	DECLARE tentativas INT;

	WHILE i < 5 DO
		SET i = i + 1;
		-- MS, ED, RP, EK (espada e escudo), EK (Avenger)
		SET amostra = ELT(i, 'Sorcerer Sample', 'Druid Sample', 'Paladin Sample', 'Knight Sample', 'Knight Sample');

		SET tentativas = 0;
		REPEAT
			SET tentativas = tentativas + 1;
			SET nome = hegemony_nome();
			-- Depois de 20 colisoes, nome de duas palavras: o espaco vira 4.704 x 4.704.
			IF tentativas > 20 THEN
				SET nome = CONCAT(nome, ' ', hegemony_nome());
			END IF;
		UNTIL NOT EXISTS (SELECT 1 FROM `players` WHERE `players`.`name` = nome) END REPEAT;

		SET sexo = FLOOR(RAND() * 2);

		DROP TEMPORARY TABLE IF EXISTS `hegemony_novo`;
		CREATE TEMPORARY TABLE `hegemony_novo` AS SELECT * FROM `players` WHERE `players`.`name` = amostra LIMIT 1;
		SET novo = (SELECT MAX(`id`) + 1 FROM `players`);
		UPDATE `hegemony_novo` SET
			`id` = novo, `name` = nome, `account_id` = conta, `sex` = sexo,
			`looktype` = IF(sexo = 1, ELT(i, 130, 144, 129, 131, 143), ELT(i, 138, 148, 137, 139, 147)),
			`town_id` = 9, `posx` = 0, `posy` = 0, `posz` = 0,
			`lastlogin` = 0, `lastlogout` = 0;
		INSERT INTO `players` SELECT * FROM `hegemony_novo`;

		INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`)
			VALUES (novo, 11, 101, 23396, 1, '');  -- store inbox
		IF i = 5 THEN
			INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES (novo, 98700, 1);
		END IF;
	END WHILE;
	DROP TEMPORARY TABLE IF EXISTS `hegemony_novo`;
END$$

CREATE TRIGGER `hegemony_conta_nova` AFTER INSERT ON `accounts` FOR EACH ROW
BEGIN
	IF NEW.`type` < 4 THEN
		CALL hegemony_criar_personagens(NEW.`id`);
	END IF;
END$$

DELIMITER ;

-- O formulario de conta do MyAAC criava um personagem junto: com os cinco
-- automaticos, seria o sexto.
DELETE FROM `myaac_settings` WHERE `name` = 'core' AND `key` = 'account_create_character_create';
INSERT INTO `myaac_settings` (`name`, `key`, `value`) VALUES ('core', 'account_create_character_create', 'false');
