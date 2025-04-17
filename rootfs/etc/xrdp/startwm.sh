#!/bin/sh
export DISPLAY=:10
if test -r /etc/profile; then
	. /etc/profile
fi
if test -r ~/.profile; then
	. ~/.profile
fi
exec /usr/bin/icewm-session
