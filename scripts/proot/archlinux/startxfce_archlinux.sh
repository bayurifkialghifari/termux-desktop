#!/data/data/com.termux/files/usr/bin/bash

# Start Xfce4 in the Arch Linux ARM PRoot container.
set -euo pipefail

# Pass a username as the first argument to override wowo.
desktop_user="${1:-wowo}"
: "${TMPDIR:?Run this script inside Termux}"

# Enable PulseAudio over localhost.
pulseaudio --start --exit-idle-time=-1
if ! pactl list short modules | grep -F "module-native-protocol-tcp" >/dev/null; then
    pactl load-module module-native-protocol-tcp \
        auth-ip-acl=127.0.0.1 listen=127.0.0.1 >/dev/null
fi

# Start Termux:X11, or reuse it when switching desktops.
if [ ! -S "$TMPDIR/.X11-unix/X0" ]; then
    XDG_RUNTIME_DIR="$TMPDIR" termux-x11 :0 > "$HOME/termux-x11.log" 2>&1 &
fi

for attempt in {1..15}; do
    if [ -S "$TMPDIR/.X11-unix/X0" ]; then
        break
    fi
    sleep 1
done

if [ ! -S "$TMPDIR/.X11-unix/X0" ]; then
    printf "%s\n" "Termux:X11 did not start. Check $HOME/termux-x11.log." >&2
    exit 1
fi

# Open the Termux:X11 Android activity.
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

# Log in as the desktop user with the shared X11 socket and a private D-Bus session.
proot-distro login archlinux --user "$desktop_user" --shared-tmp -- \
    /usr/bin/env DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 \
    /usr/bin/dbus-run-session -- /bin/bash -c '
set -euo pipefail
export XDG_RUNTIME_DIR="$HOME/.local/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY

exec xfce4-session
'
