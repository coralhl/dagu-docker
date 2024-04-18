#!/bin/bash

### Set the desired timezone
if [ ! -z "$TZ" ]; then
  sudo rm -f /etc/localtime && 
  sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  sudo echo $TZ > /etc/timezone
fi

### Set user
PUID=${PUID:-1000}
PGID=${PGID:-1000}

sudo groupmod -o -g "$PGID" abc
sudo usermod -o -u "$PUID" abc

echo '
     ┌                            ┐
                                
       ███ ███ ██████ ███ ███ ███  
      ░███░███░██████░███░███░███  
      ░███████░███░░ ░███░███░███  
      ░░░███░ ░███   ░███░███░███  
       ███████░███   ░███░███░███  
      ░███░███░██████░███░███░███  
      ░███░███░██████░███░███░███  
      ░░░ ░░░ ░░░░░░ ░░░ ░░░ ░░░   
     └                            ┘
           Created by XCIII:
      https://github.com/coralhl/

───────────────────────────────────────'
echo "
PUID                    = $(id -u abc)
PGID                    = $(id -g abc)
TZ                      = $TZ
───────────────────────────────────────
"

sudo lsiown -R abc:abc /app

### Start dagu server
# sudo -u abc -- sh -c 'dagu start-all'
dagu start-all
