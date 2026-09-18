-- Hegemony PvP: textos do site (noticias e paginas do MyAAC).
-- Idempotente: pode rodar de novo.
--
-- Aplicar com:
--   docker exec -i otbr-db-1 sh -c \
--     'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
--     < docker/hegemony/04-site.sql
--
-- As noticias antigas (em ingles) prometiam coisa que o servidor nao tem:
-- "Retro PvP", frags desligados, loot 2x, Wheel of Destiny, Forge. Estas
-- descrevem as regras que valem desde 18/09/2026 (ver
-- data-otservbr-global/scripts/hegemony/). O visual e os textos fixos ficam
-- no tema: docker/quickstart/myaac/templates/hegemony/.

SET NAMES utf8mb4;

-- ---------------------------------------------------------------- noticias

DELETE FROM `myaac_news` WHERE `title` IN (
	'WELCOME TO HEGEMONY PVP - TACTICAL WAR ONLINE',
	'HEGEMONY PVP - SERVER RATES & FEATURE BREAKDOWN',
	'Venore em guerra',
	'Como entrar no Hegemony'
);

INSERT INTO `myaac_news` (`title`, `body`, `type`, `date`, `category`, `player_id`, `last_modified_by`, `last_modified_date`, `comments`, `article_text`, `article_image`, `hide`) VALUES
('Como entrar no Hegemony',
'<p>O servidor roda numa máquina da turma, dentro de uma rede privada do <b>Tailscale</b>. São quatro passos:</p>
<ol>
<li>Instale o <a href="https://tailscale.com/download" target="_blank" rel="noopener">Tailscale</a>, entre com uma conta Google ou Microsoft e aceite o convite que você recebeu. Deixe ele ligado enquanto joga.</li>
<li>Baixe o cliente na página <a href="/index.php/downloads">Baixar o cliente</a> e extraia a pasta inteira.</li>
<li><a href="/index.php/account/create">Crie sua conta</a>. Ela já nasce premium e com cinco personagens.</li>
<li>Abra o <b>Hegemony.exe</b>, entre com o <b>e-mail</b> (não o nome da conta) e a senha, e escolha com quem lutar.</li>
</ol>
<p>Não conectou? Quase sempre é o Tailscale desligado.</p>',
1, UNIX_TIMESTAMP() - 60, 1, 0, 0, 0, '', '', '', 0),

('Venore em guerra',
'<p>O Hegemony é PvP puro dentro de <b>Venore</b>: a cidade do térreo para cima, sem esgoto e sem nenhuma saída. Todo mundo começa no mesmo ponto e a diferença está no que você tira dos outros.</p>
<h3>Todo mundo nasce igual</h3>
<ul>
<li>Sua conta é premium e já vem com <b>cinco personagens nível 80</b>: Master Sorcerer, Elder Druid, Royal Paladin e dois Elite Knights, um com Magic Sword e escudo, outro com a Avenger.</li>
<li>Cada um nasce com o kit da vocação e com <b>todas as magias</b> liberadas (cada uma respeita o nível mínimo dela).</li>
<li>Runas, poções, munição e comida são <b>infinitas</b>.</li>
</ul>
<h3>Matar e morrer</h3>
<ul>
<li>Matar outro jogador dá experiência.</li>
<li>Quem dá o último golpe fica <b>15 minutos marcado</b>: não sai do jogo nem entra em área protegida.</li>
<li>Morrer derruba <b>tudo</b> no corpo, e você volta ao templo no nível 80 com kit novo.</li>
<li>Sair do jogo também devolve nível e skills ao 80. Os itens ficam com você.</li>
</ul>
<h3>O receptador</h3>
<p>Numa rua ao sul, longe das áreas protegidas, fica <b>Varg</b>. Diga <code>vender</code> e ele compra o equipamento que você saqueou (o seu próprio, não). O equipamento de um personagem vale exatamente <b>10.000</b>, o preço de um <b>Stone Skin Amulet</b> ou de um <b>Might Ring</b>, as únicas coisas que ele vende. O caminho até ele fica fora das áreas protegidas, e quem vai carrega o saque.</p>',
1, UNIX_TIMESTAMP(), 1, 0, 0, 0, '', '', '', 0);

-- ---------------------------------------------------------------- paginas

UPDATE `myaac_pages` SET `title` = 'Baixar o cliente', `enable_tinymce` = 0, `body` =
'<p>O Hegemony tem cliente próprio, com o visual do servidor e a lista de servidores já configurada. Não instala nada: é extrair e abrir.</p>
<div class="caixa-destaque">
<p><a class="btn-hegemony primary" href="/cliente/Hegemony.zip">Baixar Hegemony.zip</a></p>
<p style="margin:10px 0 0;">Cerca de 260 MB. Windows 10 ou 11.</p>
</div>
<h3>Passo a passo</h3>
<ol>
<li>Instale o <a href="https://tailscale.com/download" target="_blank" rel="noopener">Tailscale</a> e aceite o convite. É ele que liga você ao servidor.</li>
<li>Extraia a pasta <b>Hegemony</b> inteira em qualquer lugar, por exemplo em Documentos.</li>
<li>Abra o <b>Hegemony.exe</b>.</li>
<li>Escolha o servidor na lista e entre com o <b>e-mail</b> e a senha da sua conta.</li>
</ol>
<h3>Se algo der errado</h3>
<ul>
<li><b>Não conecta:</b> confira se o Tailscale está ligado.</li>
<li><b>E-mail ou senha incorretos:</b> o login é pelo e-mail, não pelo nome da conta.</li>
<li><b>O Windows avisou que o programa é desconhecido:</b> clique em "Mais informações" e em "Executar assim mesmo". O cliente é compilado aqui, sem assinatura digital.</li>
</ul>'
WHERE `name` = 'downloads';

UPDATE `myaac_pages` SET `title` = 'Regras', `enable_tinymce` = 0, `body` =
'<h3>O mundo</h3>
<ul>
<li>O mapa é <b>Venore</b> do térreo para cima: ruas, prédios e telhados. As escadas que desciam para o pântano e para o esgoto foram fechadas, e não há barco nem carruagem.</li>
<li>PvP livre: qualquer um ataca qualquer um fora das áreas protegidas (templo e depósito).</li>
</ul>
<h3>Personagens</h3>
<ul>
<li>A conta nasce premium, com cinco personagens nível 80: Master Sorcerer, Elder Druid, Royal Paladin e dois Elite Knights (espada e escudo, ou Avenger).</li>
<li>Todas as magias da vocação vêm liberadas, cada uma no nível mínimo dela.</li>
<li>Runas, poções, munição e comida são infinitas.</li>
</ul>
<h3>Kits</h3>
<table>
<tr><th>Vocação</th><th>Equipamento</th></tr>
<tr><td>Master Sorcerer</td><td>Yalahari Mask, Blue Robe, Blue Legs, Wand of Defiance, Spellbook of Lost Souls, Boots of Haste</td></tr>
<tr><td>Elder Druid</td><td>Yalahari Mask, Blue Robe, Blue Legs, Glacial Rod, Spellbook of Lost Souls, Boots of Haste</td></tr>
<tr><td>Royal Paladin</td><td>Zaoan Helmet, Paladin Armor, Zaoan Legs, Ironworker com Drill Bolts na aljava, Boots of Haste</td></tr>
<tr><td>Elite Knight (escudo)</td><td>Zaoan Helmet, Zaoan Armor, Zaoan Legs, Magic Sword, Shield of Corruption, Boots of Haste</td></tr>
<tr><td>Elite Knight (Avenger)</td><td>Zaoan Helmet, Zaoan Armor, Zaoan Legs, The Avenger, Boots of Haste</td></tr>
</table>
<p>Na mochila, infinitas: Magic Wall, Disintegrate, Destroy Field e Fire Bomb para todos; Sudden Death para os magos; Paralyse e Wild Growth para o Elder Druid; e as poções da vocação. Todo mundo leva também um Brown Mushroom que nunca acaba.</p>
<h3>Matar, morrer e sair</h3>
<ul>
<li>Matar outro jogador dá experiência.</li>
<li>Quem dá o último golpe fica 15 minutos marcado: não sai do jogo nem entra em área protegida.</li>
<li>Morrer derruba tudo no corpo: equipamento, mochila e o que houver nela. Você volta ao templo no nível 80, com as skills do começo e um kit novo.</li>
<li>Sair do jogo também devolve nível, magic level e skills ao 80. Os itens ficam.</li>
</ul>
<h3>Economia</h3>
<ul>
<li>O único comerciante é <b>Varg, o receptador</b>, numa rua ao sul, longe das áreas protegidas.</li>
<li><code>vender</code>: ele compra o equipamento de kit que estiver na sua mochila, desde que não seja o seu.</li>
<li>O equipamento de um personagem vale exatamente 10.000, o preço de um Stone Skin Amulet ou de um Might Ring (<code>comprar</code>).</li>
<li>Ouro na mochila também cai quando você morre. Guarde no depósito ou no banco o que não quer perder.</li>
</ul>
<h3>Convivência</h3>
<ul>
<li>É um teste entre amigos: nada de bot, macro ou abuso de bug. Achou um bug, avise.</li>
</ul>'
WHERE `name` = 'rules';

-- Texto que aparece para aceite no cadastro.
UPDATE `myaac_pages` SET `title` = 'Regras', `enable_tinymce` = 0, `body` =
'<p>Hegemony PvP é um servidor de teste entre amigos. Nada de bot, macro ou abuso de bug; achou um bug, avise. Tudo o que você carrega cai quando você morre, e os personagens voltam ao nível 80 ao morrer e ao sair do jogo.</p>'
WHERE `name` = 'rules_on_the_page';

UPDATE `myaac_pages` SET `title` = 'Comandos e NPC', `enable_tinymce` = 0, `body` =
'<h3>Varg, o receptador</h3>
<table>
<tr><th>Diga</th><th>O que acontece</th></tr>
<tr><td><code>oi</code> ou <code>hi</code></td><td>Começa a conversa.</td></tr>
<tr><td><code>vender</code></td><td>Vende o equipamento de kit que está na sua mochila. O seu próprio kit ele não compra.</td></tr>
<tr><td><code>comprar</code> ou <code>trade</code></td><td>Abre a loja: Stone Skin Amulet e Might Ring, 10.000 cada.</td></tr>
<tr><td><code>lista</code></td><td>Mostra quanto ele paga por cada peça.</td></tr>
</table>
<h3>No chat</h3>
<table>
<tr><th>Comando</th><th>Para que serve</th></tr>
<tr><td><code>!online</code></td><td>Quem está no jogo.</td></tr>
<tr><td><code>!balance</code>, <code>!deposit</code>, <code>!withdraw</code></td><td>Banco, de qualquer lugar: ouro guardado lá não cai quando você morre.</td></tr>
<tr><td><code>!time</code></td><td>Hora do servidor.</td></tr>
</table>'
WHERE `name` = 'commands';

-- ---------------------------------------------------------------- menu
--
-- O MyAAC le o menu do banco (myaac_menu), nao do menus.php do tema: o
-- arquivo so e importado pelo painel admin. Sem estas linhas a barra de abas
-- do site nao aparecia. Mesma lista de templates/hegemony/menus.php.
-- Categorias (common.php): 1 noticias, 2 conta, 3 comunidade, 5 guia.

DELETE FROM `myaac_menu` WHERE `template` = 'hegemony';
INSERT INTO `myaac_menu` (`template`, `name`, `link`, `access`, `blank`, `color`, `category`, `ordering`, `enabled`) VALUES
	('hegemony', 'Notícias', 'news', 0, 0, '', 1, 0, 1),
	('hegemony', 'Arquivo', 'news/archive', 0, 0, '', 1, 1, 1),
	('hegemony', 'Minha conta', 'account/manage', 0, 0, '', 2, 0, 1),
	('hegemony', 'Criar conta', 'account/create', 0, 0, '', 2, 1, 1),
	('hegemony', 'Recuperar conta', 'account/lost', 0, 0, '', 2, 2, 1),
	('hegemony', 'Baixar o cliente', 'downloads', 0, 0, '', 2, 3, 1),
	('hegemony', 'Regras', 'rules', 0, 0, '', 2, 4, 1),
	('hegemony', 'Personagens', 'characters', 0, 0, '', 3, 0, 1),
	('hegemony', 'Quem está online', 'online', 0, 0, '', 3, 1, 1),
	('hegemony', 'Últimas mortes', 'last-kills', 0, 0, '', 3, 2, 1),
	('hegemony', 'Guildas', 'guilds', 0, 0, '', 3, 3, 1),
	('hegemony', 'Magias', 'spells', 0, 0, '', 5, 0, 1),
	('hegemony', 'Comandos e NPC', 'commands', 0, 0, '', 5, 1, 1);

-- ---------------------------------------------------------------- login

-- O jogo entra pelo e-mail; o site entrava pelo nome da conta. Mesmo e-mail
-- nos dois, e o nome da conta continua aceito como reserva.
DELETE FROM `myaac_settings` WHERE `name` = 'core' AND `key` IN ('account_login_by_email', 'account_login_by_email_fallback');
INSERT INTO `myaac_settings` (`name`, `key`, `value`) VALUES
	('core', 'account_login_by_email', 'true'),
	('core', 'account_login_by_email_fallback', 'true');

-- ---------------------------------------------------------------- cadastro

-- Trava de "uma conta por IP a cada 10 minutos" desligada: o site roda atras
-- do NAT do Docker e ve TODO mundo com o mesmo IP (o gateway da rede do
-- compose, 172.19.0.1 no log das contas). Com a trava, um amigo criando conta
-- bloqueava todos os outros por 10 minutos (visto em 18/09).
DELETE FROM `myaac_settings` WHERE `name` = 'core' AND `key` = 'account_create_ip_block_cooldown';
INSERT INTO `myaac_settings` (`name`, `key`, `value`) VALUES ('core', 'account_create_ip_block_cooldown', '0');
