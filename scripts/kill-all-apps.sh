#!/usr/bin/env bash

# @TODO: remove the ones here that do nothing

pkill chromium
pkill chrome
pkill slack
pkill Slack
pkill brave
pkill Brave
pkill joplin
pkill joplin-desktop
pkill code
pkill spotify
pkill Spotify
pkill firefox
pkill signal
pkill signal-desktop
pkill Signal
pkill telegram
## @TODO: 15 or more chars doesn't work with pkill
pkill telegram-desktop
pkill Telegram
pkill Discord
pkill discord
pkill vesktop
pkill app.asar
pkill element
## @TODO: 15 or more chars doesn't work with pkill
pkill element-desktop
pkill Element
pkill electron
kill $(pidof electron)
kill $(pidof whatsapp-for-linux)
pkill vlc
kill $(pidof vlc)
