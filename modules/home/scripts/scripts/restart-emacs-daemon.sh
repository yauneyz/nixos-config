#!/bin/sh
pkill emacs
emacs --daemon
notify-send "Emacs daemon restarted"
