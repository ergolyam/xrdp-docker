#!/usr/bin/env sh

set -eu

if [ -z "${XKBMAP_LAYOUT:-}" ]; then
  exit 0
fi

DEFAULT_OPTION="grp:win_space_toggle"

if [ -n "${XKBMAP_OPTION:-}" ]; then
  DEFAULT_OPTION=$XKBMAP_OPTION
fi

if grep -q "^\[rdp_keyboard_xkbmap\]" "/etc/xrdp/xrdp_keyboard.ini"; then
    echo "The rdp_keyboard_xkbmap section is already present - I skip it."
else

tee -a /etc/xrdp/xrdp_keyboard.ini >/dev/null <<EOF

[rdp_keyboard_xkbmap]
keyboard_type=4
keyboard_subtype=1
model=pc105
options=$DEFAULT_OPTION
rdp_layouts=default_rdp_layouts
layouts_map=layouts_map_xkbmap

[layouts_map_xkbmap]
rdp_layout_us=us,$XKBMAP_LAYOUT
rdp_layout_${XKBMAP_LAYOUT}=us,$XKBMAP_LAYOUT
EOF
fi
