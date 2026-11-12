fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'hirx_hud'
author 'Hirx'
description 'HUD minimalista (vida, armadura, comida, stamina, oxigeno, voz y velocimetro) compatible con ESX, QBCore y pma-voice'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
