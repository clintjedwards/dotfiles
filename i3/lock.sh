#!/usr/bin/env bash
#
# Lock the screen with a pixelated screenshot and the lock icon on top.
# xss-lock calls this on idle, before suspend, and on `loginctl lock-session`.

icon="${1:-$HOME/.config/i3/lock.png}"

# The screenshot is a picture of whatever was on screen, so keep it in the
# runtime dir (only readable by us) rather than /tmp.
image="${XDG_RUNTIME_DIR:-/tmp}/i3lock.png"

if magick import -silent -window root "$image" &&
    magick "$image" -scale 10% -scale 1000% "$icon" -gravity center -composite "$image"; then
    # i3lock reads the image before it forks, so it's safe to remove right after.
    i3lock -i "$image"
    rm -f "$image"
else
    # Never fail to lock just because the screenshot didn't work.
    i3lock -c 000000
fi
