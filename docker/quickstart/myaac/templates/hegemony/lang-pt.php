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
			=> 'Para criar sua conta, basta informar um nome de conta, senha, país e seu endereço de e-mail.',
		'If you have done so, your account name will be shown on the following page and your account password will be sent to your email address along with further instructions.'
			=> 'Feito isso, o nome da sua conta aparecerá na próxima página e a senha será enviada para o seu e-mail junto com as instruções.',
		'If you do not receive the email with your password, please check your spam filter.'
			=> 'Se o e-mail com a senha não chegar, verifique a caixa de spam.',
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
	];
}

/** Aplica um dicionário a um trecho já renderizado. */
function hegemony_pt(string $text, array $dictionary): string {
	return strtr($text, $dictionary);
}
