<?php
defined('MYAAC') or die('Direct access not allowed!');

require_once __DIR__ . '/lang-pt.php';
$title = hegemony_pt($title, hegemony_pt_titles());
$content = hegemony_pt_final(hegemony_pt($content, hegemony_pt_content()));

/**
 * Ultimas mortes em PvP para a coluna da direita. Com o nivel voltando ao 80
 * a cada morte e a cada logout, ranking de nivel nao diz nada; quem matou
 * quem, sim. Falha de banco nao pode derrubar a pagina: vira lista vazia.
 */
function hegemony_ultimas_mortes(int $quantas = 6): array {
	global $db;
	try {
		$linhas = $db->query(
			'SELECT p.`name` AS `vitima`, d.`killed_by` AS `assassino`, d.`time` AS `quando`
			FROM `player_deaths` d JOIN `players` p ON p.`id` = d.`player_id`
			WHERE d.`is_player` = 1 ORDER BY d.`time` DESC LIMIT ' . $quantas
		);
		return $linhas ? $linhas->fetchAll() : [];
	} catch (Throwable $e) {
		return [];
	}
}

function hegemony_ha_quanto(int $quando): string {
	$s = max(0, time() - $quando);
	if ($s < 60) return 'agora mesmo';
	if ($s < 3600) return 'há ' . intdiv($s, 60) . ' min';
	if ($s < 86400) return 'há ' . intdiv($s, 3600) . ' h';
	return 'há ' . intdiv($s, 86400) . ' dia' . ($s >= 172800 ? 's' : '');
}

function hegemony_link_personagem(string $nome): string {
	return '<a href="' . getLink('characters/' . urlencode($nome)) . '">' . htmlspecialchars($nome) . '</a>';
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
	<head>
		<?php echo template_place_holder('head_start'); ?>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<?php /* O <title> vem de template_place_holder('head_start'), acima.
		         Emitir outro aqui gera markup invalido e e ignorado pelo
		         navegador, que usa sempre o primeiro. */ ?>

		<link rel="preconnect" href="https://fonts.googleapis.com">
		<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
		<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&family=Source+Sans+3:ital,wght@0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">

		<?php /* ?v=mtime: sem isto o navegador serve o CSS em cache apos cada
		         alteracao do tema, e a pagina aparece meio estilizada. */ ?>
		<link rel="stylesheet" href="<?php echo $template_path; ?>/style.css?v=<?php echo @filemtime(__DIR__ . '/style.css') ?: time(); ?>" type="text/css" />
		<script type="text/javascript">
			<?php
				$menus = get_template_menus();
				$twig->display('menu.js.html.twig', ['menus' => $menus]);
			?>
		</script>
		<script type="text/javascript" src="tools/basic.js"></script>
		<script type="text/javascript">
			<?php require 'javascript.php'; ?>
		</script>
		<?php echo template_place_holder('head_end'); ?>
	</head>

	<body onload="initMenu();">
		<?php echo template_place_holder('body_start'); ?>

		<div id="hegemony-app">
			<header id="hegemony-header">
				<div class="header-overlay"></div>
				<div class="header-content">
					<div class="hero-texto">
						<h1>Hegemony PvP</h1>
						<p class="hero-chamada">Venore em guerra. <span>Todo mundo nasce no 80.</span></p>
						<p class="hero-apoio">PvP livre na cidade inteira: quem mata sobe, quem morre perde tudo e volta ao começo.</p>
						<div class="hero-acoes">
							<a href="<?php echo getLink('account/create'); ?>" class="btn-hegemony primary">Criar conta</a>
							<a href="<?php echo getLink('downloads'); ?>" class="btn-hegemony secondary">Baixar o cliente</a>
						</div>
					</div>

					<div class="server-status-pill">
						<?php if ($status['online']): ?>
							<div class="status-indicator online"></div>
							<div class="status-info">
								<span class="status-label">Servidor online</span>
								<?php /* maxPlayers = 0 no config.lua significa ilimitado; mostrar
								         "0 / 0" passaria a impressao de servidor vazio e quebrado. */ ?>
								<span class="status-val"><?php echo (int) $status['players']; ?><?php
									if ((int) $status['playersMax'] > 0) { echo ' / ' . (int) $status['playersMax']; }
								?> em combate</span>
							</div>
						<?php else: ?>
							<div class="status-indicator offline"></div>
							<div class="status-info">
								<span class="status-label">Servidor</span>
								<span class="status-val red">Offline</span>
							</div>
						<?php endif; ?>
					</div>
				</div>
			</header>

			<nav id="hegemony-nav">
				<div class="nav-tabs-container">
					<?php
					foreach ($config['menu_categories'] as $id => $cat) {
						if (($id != MENU_CATEGORY_SHOP || $config['gifts_system']) && isset($menus[$id])) { ?>
					<button id="<?php echo $cat['id']; ?>" class="nav-tab" onclick="menuSwitch('<?php echo $cat['id']; ?>');"><?php echo $cat['name']; ?></button>
					<?php
						}
					}
					?>
				</div>
			</nav>

			<div id="hegemony-submenu">
				<?php
				foreach ($menus as $category => $menu) {
					if (!isset($menus[$category])) {
						continue;
					}

					echo '<div id="' . $config['menu_categories'][$category]['id'] . '-submenu" class="submenu-row" style="display:none;">';

					foreach ($menus[$category] as $link) {
						echo '<a href="' . $link['link_full'] . '" ' . $link['target_blank'] . ' class="submenu-item">' . $link['name'] . '</a>';
					}

					echo '</div>';
				}
				?>
			</div>

			<div id="hegemony-main">
				<div class="layout-grid">
					<aside class="sidebar-left">
						<div class="panel-box">
							<div class="panel-header">
								<h3>Sua conta</h3>
							</div>
							<div class="panel-body">
								<a href="<?php echo getLink('account/create'); ?>" class="btn-hegemony primary block">Criar conta</a>
								<a href="<?php echo getLink('account/manage'); ?>" class="btn-hegemony secondary block">Entrar na conta</a>
								<a href="<?php echo getLink('downloads'); ?>" class="btn-hegemony secondary block">Baixar o cliente</a>
							</div>
						</div>

						<div class="panel-box">
							<div class="panel-header">
								<h3>Regras de Venore</h3>
							</div>
							<div class="panel-body">
								<ul class="regras-rapidas">
									<li><strong>Mapa</strong>Venore do térreo para cima, sem esgoto. PvP livre.</li>
									<li><strong>Nascimento</strong>Nível 80 com o kit da vocação. Cada conta vem com 5 personagens.</li>
									<li><strong>Matar</strong>Dá experiência. Quem mata fica 15 min marcado: sem logout e sem área protegida.</li>
									<li><strong>Morrer</strong>Tudo cai no corpo e você volta ao 80 com kit novo.</li>
									<li><strong>Sair do jogo</strong>Nível e skills voltam ao 80. Os itens ficam.</li>
									<li><strong>Suprimentos</strong>Runas, poções, munição e comida infinitas.</li>
									<li><strong>Varg, o receptador</strong>Compra o equipamento que você saquear e vende Stone Skin e Might Ring por 10.000.</li>
								</ul>
							</div>
						</div>
					</aside>

					<main class="content-center">
						<div class="content-box">
							<div class="content-header">
								<h2><?php echo $title; ?></h2>
							</div>
							<div class="content-body">
								<?php echo $content; ?>
							</div>
						</div>
					</main>

					<aside class="sidebar-right">
						<div class="panel-box">
							<div class="panel-header">
								<h3>Últimas mortes</h3>
							</div>
							<div class="panel-body">
								<?php $mortes = hegemony_ultimas_mortes(); ?>
								<?php if (empty($mortes)): ?>
									<p class="abates-vazio">Ninguém caiu ainda. Seja o primeiro.</p>
								<?php else: ?>
									<ul class="abates">
										<?php foreach ($mortes as $m): ?>
											<li>
												<span class="quem"><?php echo hegemony_link_personagem($m['assassino']); ?></span>
												derrubou
												<span class="caiu"><?php echo hegemony_link_personagem($m['vitima']); ?></span>
												<span class="quando"><?php echo hegemony_ha_quanto((int) $m['quando']); ?></span>
											</li>
										<?php endforeach; ?>
									</ul>
								<?php endif; ?>
								<a href="<?php echo getLink('last-kills'); ?>" class="btn-hegemony secondary block" style="margin-top:12px;">Ver todas</a>
							</div>
						</div>

						<div class="panel-box">
							<div class="panel-header">
								<h3>Como jogar</h3>
							</div>
							<div class="panel-body">
								<ol class="passos">
									<li>Instale o <a href="https://tailscale.com/download" target="_blank" rel="noopener">Tailscale</a> e aceite o convite que você recebeu.</li>
									<li><a href="<?php echo getLink('downloads'); ?>">Baixe o cliente</a> e extraia a pasta.</li>
									<li><a href="<?php echo getLink('account/create'); ?>">Crie sua conta</a>: ela já vem com 5 personagens.</li>
									<li>Abra o <strong>Hegemony.exe</strong>, entre com o <strong>e-mail</strong> e escolha com quem lutar.</li>
								</ol>
							</div>
						</div>
					</aside>
				</div>
			</div>

			<footer id="hegemony-footer">
				<div class="footer-content">
					<p>&copy; <?php echo date('Y'); ?> <strong>Hegemony PvP</strong>. Servidor privado de teste entre amigos.</p>
					<p class="footer-credits">MyAAC e Canary. Tibia é marca registrada da CipSoft GmbH.</p>
				</div>
			</footer>
		</div>

		<?php echo template_place_holder('body_end'); ?>
	</body>
</html>
