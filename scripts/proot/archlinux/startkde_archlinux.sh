#!/data/data/com.termux/files/usr/bin/bash

# Start KDE Plasma in Arch using the same login sequence as the Debian launcher.
set -e

desktop_user="${1:-wowo}"
: "${TMPDIR:?Run this script inside Termux}"

# Stop the previous X11 session before starting a fresh display.
pkill -f "[t]ermux.x11" 2>/dev/null || true
sleep 1

# Enable PulseAudio over localhost.
pulseaudio --start --exit-idle-time=-1
if ! pactl list short modules | grep -F "module-native-protocol-tcp" >/dev/null; then
    pactl load-module module-native-protocol-tcp \
        auth-ip-acl=127.0.0.1 listen=127.0.0.1 >/dev/null
fi

# Prepare Termux:X11 and open its Android activity.
export XDG_RUNTIME_DIR="$TMPDIR"
termux-x11 :0 > "$HOME/termux-x11.log" 2>&1 &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
sleep 1

# Enter PRoot as root, then switch users before setting the display environment.
proot-distro login archlinux --shared-tmp -- /bin/su - "$desktop_user" -c '
set -e
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export TMPDIR=/tmp
export XDG_RUNTIME_DIR="$HOME/.local/run"
export XDG_SESSION_TYPE=x11
# PRoot cannot run the namespaces used by Glycin image-loader sandboxing.
export GLYCIN_DISABLE_SANDBOX=i-know-the-risks
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
unset GDK_BACKEND WAYLAND_DISPLAY SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS

if ! command -v xdpyinfo >/dev/null 2>&1; then
    printf "%s\n" "Install xorg-xdpyinfo inside Arch before starting KDE Plasma." >&2
    exit 1
fi

# Check the connection inside Arch rather than relying on a socket file existing.
display_ready=false
for attempt in {1..15}; do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2> "$HOME/kde-display.log"; then
        display_ready=true
        break
    fi
    sleep 1
done

if [ "$display_ready" != true ]; then
    printf "%s\n" "Cannot connect to Termux:X11 on $DISPLAY." \
        "Check ~/kde-display.log in Arch and ~/termux-x11.log in Termux." >&2
    cat "$HOME/kde-display.log" >&2
    exit 1
fi

# Run the nested desktop inside a private D-Bus session.
exec dbus-run-session -- /bin/bash -s << "DESKTOP_SESSION"
set -euo pipefail

export XDG_CURRENT_DESKTOP=KDE
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

wait_for_socket() {
    for attempt in {1..15}; do
        if ! kill -0 "$1" 2>/dev/null; then
            return 1
        fi
        if [ -S "$XDG_RUNTIME_DIR/$2" ]; then
            return 0
        fi
        sleep 1
    done
    return 1
}

if [ -S "$XDG_RUNTIME_DIR/wayland-weston" ]; then
    printf "%s\n" "A Weston session is already running. Stop it before starting another desktop." >&2
    exit 1
fi

weston --backend=x11 --renderer=pixman \
    --socket=wayland-weston --width=1280 --height=720 \
    --log="$HOME/weston-plasma.log" &
weston_pid=$!
cleanup() {
    kill "$weston_pid" 2>/dev/null || true
    wait "$weston_pid" 2>/dev/null || true
}
trap cleanup EXIT

if ! wait_for_socket "$weston_pid" "wayland-weston"; then
    printf "%s\n" "Weston did not start. Check $HOME/weston-plasma.log." >&2
    exit 1
fi
export WAYLAND_DISPLAY=wayland-weston
export XDG_SESSION_TYPE=wayland

kwin_wayland --wayland-display=wayland-weston --socket=wayland-plasma \
    --width=1280 --height=720 --xwayland --exit-with-session=plasmashell
DESKTOP_SESSION
'
