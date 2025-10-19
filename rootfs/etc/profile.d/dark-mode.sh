#!/usr/bin/env sh

if [ -f /tmp/darkmode ]; then
    export GTK_THEME="Adwaita:dark"
    export GDK_THEME="Adwaita:dark"
    export QT_STYLE_OVERRIDE="Adwaita-Dark"
fi

