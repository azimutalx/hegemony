-- ============================================================================
-- HEGEMONY PVP - ADMIN ACCOUNTS AND PLAYERS SEED SCRIPT
-- ============================================================================

-- 1. Create GOD Account (login: god@hegemony.com / password: god123)
-- Password SHA-1: 3f86be8cbe1fa89a27d47b9254cd3317bcd8d4df ('god123')
INSERT INTO `accounts` 
(`id`, `name`, `password`, `email`, `type`, `coins`, `web_flags`, `created`) 
VALUES 
(1, 'god', '3f86be8cbe1fa89a27d47b9254cd3317bcd8d4df', 'god@hegemony.com', 6, 100000, 3, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE 
`email` = 'god@hegemony.com', `password` = '3f86be8cbe1fa89a27d47b9254cd3317bcd8d4df', `type` = 6, `web_flags` = 3, `coins` = 100000;

-- 2. Create Web Admin Account (login: myaac@hegemony.com / password: admin123)
-- Password SHA-1: 01b307ac9070d629a286e507a042e6a6b57fc331 ('admin123')
INSERT INTO `accounts` 
(`id`, `name`, `password`, `email`, `type`, `coins`, `web_flags`, `created`) 
VALUES 
(2, 'admin', '01b307ac9070d629a286e507a042e6a6b57fc331', 'myaac@hegemony.com', 6, 100000, 3, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE 
`email` = 'myaac@hegemony.com', `password` = '01b307ac9070d629a286e507a042e6a6b57fc331', `type` = 6, `web_flags` = 3;

-- 3. Create Test PvP Account (login: teste@hegemony.com / password: test)
-- Password SHA-1: a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 ('test')
INSERT INTO `accounts`
(`id`, `name`, `password`, `email`, `type`, `coins`, `created`)
VALUES
(101, 'test1', 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3', 'teste@hegemony.com', 1, 10000, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
`email` = 'teste@hegemony.com', `type` = 1, `coins` = 10000;

-- 3. Create GOD & ADM Characters on Account 1 (god)
INSERT INTO `players`
(`name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `mana`, `manamax`, `town_id`, `conditions`, `cap`, `sex`)
VALUES
('GOD Hegemony', 6, 1, 1000, 1, 10000, 10000, 205847400, 106, 95, 78, 116, 302, 10000, 10000, 1, '', 100000, 1),
('ADM Hegemony', 6, 1, 500, 4, 5000, 5000, 20584740, 106, 95, 78, 116, 75, 5000, 5000, 1, '', 50000, 1)
ON DUPLICATE KEY UPDATE `group_id` = 6, `level` = 1000;

-- 4. Create Community Manager Character on Account 2 (admin)
INSERT INTO `players`
(`name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `mana`, `manamax`, `town_id`, `conditions`, `cap`, `sex`)
VALUES
('Community Manager', 5, 2, 300, 2, 3000, 3000, 5000000, 106, 95, 78, 116, 75, 3000, 3000, 1, '', 30000, 1)
ON DUPLICATE KEY UPDATE `group_id` = 5;
