fx_version 'adamant'

game 'gta5'

description 'Starbucks'
author 'FanKolei'
lua54 'yes'
version '1.0'
legacyversion '1.0'

shared_script  {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/*.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/*.lua'
}

dependencies {
	'es_extended',
	'ox_lib',
	'esx_billing',
	'esx_vehicleshop'
}
