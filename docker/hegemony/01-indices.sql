-- Correcoes de banco do Hegemony PvP. Idempotente: pode rodar de novo.
--
-- Aplicar com:
--   docker exec -i otbr-db-1 sh -c \
--     'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
--     < docker/hegemony/01-indices.sql
--
-- Nao virou migration Lua do datapack de proposito: as migrations vivem dentro
-- da imagem publicada, entao um arquivo novo em data-otservbr-global/migrations/
-- nunca seria executado sem rebuild.

-- 1) players_online era ENGINE=MEMORY.
--
-- Duas consequencias medidas em 18/09/2026: a tabela inteira sumia a cada
-- restart do MariaDB (o site mostrava ninguem online ate o proximo tick, que e
-- de 10 minutos), e a FOREIGN KEY declarada no schema.sql foi silenciosamente
-- descartada na criacao, porque o engine MEMORY nao suporta chave estrangeira.
ALTER TABLE `players_online` ENGINE = InnoDB;

-- 2) player_items: filesort em todo login.
--
-- O carregamento do personagem roda
--   SELECT ... FROM player_items WHERE player_id = ? ORDER BY sid DESC
-- A PK e (player_id, pid, sid): o prefixo resolve o WHERE, mas nao a ordenacao.
-- EXPLAIN antes desta correcao: "Using where; Using filesort".
-- As tabelas irmas player_depotitems e player_inboxitems ja tem o indice certo
-- (UNIQUE player_id, sid) — esta ficou para tras no schema do upstream.
CREATE INDEX IF NOT EXISTS `player_items_player_sid`
	ON `player_items` (`player_id`, `sid`);

-- 3) player_deaths: sem indice em `time`.
--
-- A aba de mortes da Cyclopedia filtra por intervalo de tempo e ordena por
-- `time DESC`. EXPLAIN antes: type=ALL, "Using filesort". Num servidor PvP esta
-- e a tabela que mais cresce e a aba que mais se abre.
CREATE INDEX IF NOT EXISTS `player_deaths_time`
	ON `player_deaths` (`time`);

-- 4) player_charms: nenhum indice alem do implicito da FK.
--
-- O titulo de highscore de charms roda, a cada login,
--   SELECT ... FROM player_charms pc JOIN players p ...
--   WHERE p.group_id < 3 ORDER BY pc.charm_points DESC LIMIT 1
-- EXPLAIN antes: type=ALL sobre player_charms + filesort.
CREATE INDEX IF NOT EXISTS `player_charms_points`
	ON `player_charms` (`charm_points`);
