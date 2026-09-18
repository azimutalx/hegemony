<?php
defined('MYAAC') or die('Direct access not allowed!');

require_once __DIR__ . '/lang-pt.php';
$title = hegemony_pt($title, hegemony_pt_titles());
$content = hegemony_pt($content, hegemony_pt_content());
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

		<!-- Google Fonts -->
		<link rel="preconnect" href="https://fonts.googleapis.com">
		<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
		<link href="https://fonts.googleapis.com/css2?family=Outfit:ital,wght@0,400;0,700;0,900;1,700;1,900&family=Roboto+Condensed:ital,wght@0,400;0,700;1,700&display=swap" rel="stylesheet">
		
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
			<!-- TOP MILITARY NAVIGATION / BANNER -->
			<header id="hegemony-header">
				<div class="header-overlay"></div>
				<div class="header-content">
					<div class="brand-logo-container">
						<img src="<?php echo $template_path; ?>/images/logo.jpg" alt="Hegemony PvP Logo" class="hegemony-brand-logo" />
						<div class="brand-titles">
							<h1 class="hegemony-title">HEGEMONY <span>PvP</span></h1>
							<p class="hegemony-subtitle">CONFLITO GLOBAL & DOMÍNIO DE TERRITÓRIO</p>
						</div>
					</div>
					
					<div class="server-status-pill">
						<?php if($status['online']): ?>
							<div class="status-indicator online"></div>
							<div class="status-info">
								<span class="status-label">REDE TÁTICA</span>
								<?php /* maxPlayers = 0 no config.lua significa ilimitado; mostrar
								         "0 / 0" passaria a impressao de servidor vazio e quebrado. */ ?>
								<span class="status-val"><?php echo (int) $status['players']; ?><?php
									if ((int) $status['playersMax'] > 0) { echo ' / ' . (int) $status['playersMax']; }
								?> COMBATENTES</span>
							</div>
						<?php else: ?>
							<div class="status-indicator offline"></div>
							<div class="status-info">
								<span class="status-label">STATUS DO SERVIDOR</span>
								<span class="status-val red">OFFLINE / MANUTENÇÃO</span>
							</div>
						<?php endif; ?>
					</div>
				</div>
			</header>

			<!-- MAIN NAVIGATION BAR -->
			<nav id="hegemony-nav">
				<div class="nav-tabs-container">
					<?php
					foreach($config['menu_categories'] as $id => $cat) {
						if (($id != MENU_CATEGORY_SHOP || $config['gifts_system']) && isset($menus[$id])) { ?>
					<button id="<?php echo $cat['id']; ?>" class="nav-tab" onclick="menuSwitch('<?php echo $cat['id']; ?>');"><?php echo $cat['name']; ?></button>
					<?php
						}
					}
					?>
				</div>
			</nav>

			<!-- SUBMENU BAR -->
			<div id="hegemony-submenu">
				<?php
				foreach($menus as $category => $menu) {
					if(!isset($menus[$category])) {
						continue;
					}

					echo '<div id="' . $config['menu_categories'][$category]['id'] . '-submenu" class="submenu-row" style="display:none;">';

					foreach($menus[$category] as $link) {
						echo '<a href="' . $link['link_full'] . '" ' . $link['target_blank'] . ' class="submenu-item">' . $link['name'] . '</a>';
					}

					echo '</div>';
				}
				?>
			</div>

			<!-- MAIN CONTAINER LAYOUT -->
			<div id="hegemony-main">
				<div class="layout-grid">
					<!-- LEFT SIDEBAR -->
					<aside class="sidebar-left">
						<div class="panel-box action-panel">
							<div class="panel-header">
								<h3>CENTRO DE COMANDO</h3>
							</div>
							<div class="panel-body">
								<a href="<?php echo getLink('account/create'); ?>" class="btn-hegemony primary block">
									<span>CRIAR CONTA</span>
								</a>
								<a href="<?php echo getLink('account/manage'); ?>" class="btn-hegemony secondary block">
									<span>ACESSAR CONTA</span>
								</a>
								<a href="<?php echo getLink('downloads'); ?>" class="btn-hegemony danger block">
									<span>BAIXAR CLIENTE</span>
								</a>
							</div>
						</div>

						<div class="panel-box">
							<div class="panel-header">
								<h3>INFORMAÇÕES DE GUERRA</h3>
							</div>
							<div class="panel-body info-list">
								<div class="info-row">
									<span>Tipo de Mundo:</span>
									<span class="highlight-red">Retro PvP</span>
								</div>
								<div class="info-row">
									<span>Versão do Cliente:</span>
									<span>15.25 (cliente oficial)</span>
								</div>
								<div class="info-row">
									<span>Sistema de Frags:</span>
									<span class="highlight-blue">Desativado (sem restrição)</span>
								</div>
								<div class="info-row">
									<span>Exp por Abate:</span>
									<span class="highlight-blue">Ativado (1x)</span>
								</div>
							</div>
						</div>
					</aside>

					<!-- MAIN CONTENT AREA -->
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

					<!-- RIGHT SIDEBAR -->
					<aside class="sidebar-right">
						<div class="panel-box threat-panel">
							<div class="panel-header danger">
								<h3>MAIOR ÍNDICE DE ABATES</h3>
							</div>
							<div class="panel-body">
								<p class="panel-subtitle">Guildas e jogadores dominantes em conflito ativo.</p>
								<a href="<?php echo getLink('highscores'); ?>" class="btn-hegemony danger block">
									<span>VER RANKING</span>
								</a>
							</div>
						</div>

						<div class="panel-box">
							<div class="panel-header">
								<h3>COMUNIDADE & DISCORD</h3>
							</div>
							<div class="panel-body">
								<p style="font-size:0.88rem; color:#b2bec3; margin-bottom:12px;">Entre na sala de guerra para organizar raides de aliança e diplomacia entre guildas.</p>
								<a href="https://discord.gg" target="_blank" class="btn-hegemony secondary block">
									<span>ENTRAR NO DISCORD</span>
								</a>
							</div>
						</div>
					</aside>
				</div>
			</div>

			<!-- FOOTER -->
			<footer id="hegemony-footer">
				<div class="footer-content">
					<p>&copy; <?php echo date('Y'); ?> <strong>Hegemony PvP</strong>. Todos os direitos reservados.</p>
					<p class="footer-credits">Desenvolvido com MyAAC & Canary Engine | Feito para a guerra em Hegemony</p>
				</div>
			</footer>
		</div>

		<?php echo template_place_holder('body_end'); ?>
	</body>
</html>
