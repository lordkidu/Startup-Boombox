fx_version 'cerulean'
game  'gta5'
author 'ludwikgame'
version '1.1'
lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

client_scripts {
    'Client/client.lua'

  }

shared_scripts {
    'Shared/config.lua',
  }

server_scripts {
    'Server/server.lua',
  }
