<?php
$config['menu_default_links_color'] = '#d6aa5c';

$config['menu_categories'] = [
	MENU_CATEGORY_NEWS => ['id' => 'news', 'name' => 'Notícias'],
	MENU_CATEGORY_ACCOUNT => ['id' => 'account', 'name' => 'Conta'],
	MENU_CATEGORY_COMMUNITY => ['id' => 'community', 'name' => 'Comunidade'],
	MENU_CATEGORY_LIBRARY => ['id' => 'library', 'name' => 'Guia'],
	MENU_CATEGORY_SHOP => ['id' => 'shops', 'name' => 'Loja'],
];

$config['menus'] = require __DIR__ . '/menus.php';
