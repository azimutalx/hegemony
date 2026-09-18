<?php
$config['menu_default_links_color'] = '#0984E3';

$config['menu_categories'] = [
	MENU_CATEGORY_NEWS => ['id' => 'news', 'name' => 'LATEST NEWS'],
	MENU_CATEGORY_ACCOUNT => ['id' => 'account', 'name' => 'ACCOUNT'],
	MENU_CATEGORY_COMMUNITY => ['id' => 'community', 'name' => 'WAR COMMUNITY'],
	MENU_CATEGORY_LIBRARY => ['id' => 'library', 'name' => 'TACTICS'],
	MENU_CATEGORY_SHOP => ['id' => 'shops', 'name' => 'WAR SHOP']
];

$config['menus'] = require __DIR__ . '/menus.php';
