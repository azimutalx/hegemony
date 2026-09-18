<?php
defined('MYAAC') or die('Direct access not allowed!');

/**
 * Camada de tradução pt-BR do tema Hegemony.
 *
 * Por que isto existe: o MyAAC não tem sistema de tradução para o site. O
 * diretório system/locale/ cobre apenas o instalador e o admin. Os textos das
 * páginas ficam fixos em system/pages/ e system/, dentro da imagem Docker, e
 * portanto fora do bind mount do tema.
 *
 * Sobrescrever templates twig resolve a maior parte, mas títulos de página e
 * blocos gerados em PHP chegam ao tema já montados, em $title e $content.
 * Este arquivo traduz essas strings no último momento, dentro do tema.
 *
 * Limite conhecido: é casamento literal de string. Se o MyAAC mudar a redação
 * numa atualização, a frase volta a aparecer em inglês — degrada para o texto
 * original, nunca para markup quebrado. Ao atualizar o MyAAC, revise esta
 * lista.
 */

/** Títulos de página (vêm de $title). */
function hegemony_pt_titles(): array {
	return [
		'Create Account' => 'Criar Conta',
		'Account Management' => 'Gerenciar Conta',
		'Account Login' => 'Acessar Conta',
		'Create Character' => 'Criar Personagem',
		'Latest News' => 'Últimas Notícias',
		'Highscores' => 'Ranking',
		'Characters' => 'Personagens',
		'Guilds' => 'Guildas',
		'Houses' => 'Casas',
		'Downloads' => 'Downloads',
		'Server Info' => 'Informações do Servidor',
		'Who is online?' => 'Quem está online?',
		'Last Deaths' => 'Últimas Mortes',
		'Bans' => 'Banimentos',
		'Rules' => 'Regras',
		'Changelog' => 'Mudanças',
		'Experience Stages' => 'Estágios de Experiência',
		'Experience Table' => 'Tabela de Experiência',
		'Monsters' => 'Criaturas',
		'Spells' => 'Magias',
		'Commands' => 'Comandos',
		'Team' => 'Equipe',
		'Support' => 'Suporte',
		'Forum' => 'Fórum',
		'Points' => 'Pontos',
		'Gallery' => 'Galeria',
		'Polls' => 'Enquetes',
		'Bugtracker' => 'Reportar Bugs',
	];
}

/** Blocos de texto dentro de $content. */
function hegemony_pt_content(): array {
	return [
		'All you have to do to create your new account is to enter an account name, password, country and your email address.'
			=> 'Para criar sua conta, informe um nome de conta, seu e-mail e uma senha. A conta já nasce premium e com cinco personagens nível 80 em Venore.',
		'If you have done so, your account name will be shown on the following page and your account password will be sent to your email address along with further instructions.'
			=> 'Não há confirmação por e-mail: a conta fica pronta na hora. No jogo você entra com o e-mail e a senha.',
		'If you do not receive the email with your password, please check your spam filter.'
			=> '',
		'Also you have to agree to the terms presented below.'
			=> 'Você também precisa aceitar os termos apresentados abaixo.',
		'Your browser does not support JavaScript or its disabled!'
			=> 'Seu navegador não suporta JavaScript ou ele está desativado!',
		'Please turn it on, or be aware that some features on this website will not work correctly.'
			=> 'Ative o JavaScript, ou saiba que algumas funções do site não vão funcionar corretamente.',
		'Please upgrade your browser to improve your experience.'
			=> 'Atualize seu navegador para melhorar sua experiência.',
		' you need an account.' => ' você precisa de uma conta.',
		'To play on ' => 'Para jogar em ',
		'You are using an ' => 'Você está usando um ',
		'outdated' => 'desatualizado',
		// Cadastro concluido (system/pages/account/create.php, caminho sem
		// verificacao de e-mail, que e o nosso).
		'Your account has been created. Now you can login and create your first character. See you in Tibia!'
			=> 'Sua conta foi criada e já vem com cinco personagens nível 80 em Venore: um mago de cada, um paladino e dois cavaleiros (um com espada e escudo, outro com a Avenger). Baixe o cliente, entre com o seu <b>e-mail</b> e escolha com quem lutar.',
		'Account Created' => 'Conta criada',
		// Minha conta (system/pages/account/manage.php).
		'Welcome to your account!' => 'Bem-vindo à sua conta!',
		'Premium Account' => 'Conta premium',
		'Free Account' => 'Conta gratuita',
	];
}

/**
 * Trocas que precisam de expressao regular: frases que o MyAAC monta com
 * quebra de linha e tabulacao no meio, onde o casamento literal nao alcanca.
 */
function hegemony_pt_final(string $text): string {
	return preg_replace(
		[
			// O premium vai ate 2100 (docker/hegemony/03-contas-com-personagens.sql):
			// contar 26 mil dias so confunde.
			'/Conta premium, \d+ days left/',
			'/Account created\./',
			'/Your account (name|email|Email Address) is <b>([^<]*)<\/b><br\/>You will need the account \1 and your password to play on [^.]*\.\s*Please keep your account \1 and password in a safe place and\s*never give your account \1 or password to anybody\./',
		],
		[
			'Conta premium (permanente)',
			'Conta criada.',
			'Sua conta é <b>$2</b>.<br/>No jogo você entra com o <b>e-mail</b> e a senha. Guarde a senha e não a passe para ninguém.',
		],
		$text
	) ?? $text;
}

/** Aplica um dicionário a um trecho já renderizado. */
function hegemony_pt(string $text, array $dictionary): string {
	return strtr($text, $dictionary);
}
