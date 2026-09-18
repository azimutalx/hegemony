<?php

// Menu do site. So paginas que fazem sentido no Hegemony PvP: sem loja, casas,
// forum, estagios de experiencia ou monstros (o mapa e so Venore, o nivel
// volta ao 80 e nao ha NPC de casa nem de loja alem do receptador).
return [
	MENU_CATEGORY_NEWS => [
		'Notícias' => 'news',
		'Arquivo' => 'news/archive',
	],
	MENU_CATEGORY_ACCOUNT => [
		'Minha conta' => 'account/manage',
		'Criar conta' => 'account/create',
		'Recuperar conta' => 'account/lost',
		'Baixar o cliente' => 'downloads',
		'Regras' => 'rules',
	],
	MENU_CATEGORY_COMMUNITY => [
		'Personagens' => 'characters',
		'Quem está online' => 'online',
		'Últimas mortes' => 'last-kills',
		'Guildas' => 'guilds',
	],
	MENU_CATEGORY_LIBRARY => [
		'Magias' => 'spells',
		'Comandos e NPC' => 'commands',
	],
];
