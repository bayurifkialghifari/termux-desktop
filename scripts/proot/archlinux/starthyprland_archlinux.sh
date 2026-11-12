#!/data/data/com.termux/files/usr/bin/bash

# Start Hyprland in the Arch Linux ARM PRoot container.
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

# Aquamarine requires a usable DRM render node, even in a nested session.
render_node_available=false
for render_node in /dev/dri/renderD*; do
    if [ -c "$render_node" ] && [ -r "$render_node" ] && [ -w "$render_node" ]; then
        render_node_available=true
        break
    fi
done
if [ "$render_node_available" != true ]; then
    printf "%s\n" "Hyprland requires an accessible /dev/dri/renderD* device." \
        "This rootless PRoot setup cannot provide a compatible GPU yet." >&2
    exit 1
fi

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

if [ -S "$XDG_RUNTIME_DIR/wayland-hyprland-host" ]; then
    printf "%s\n" "A Weston session is already running. Stop it before starting another desktop." >&2
    exit 1
fi

weston --backend=x11 --renderer=gl \
    --socket=wayland-hyprland-host --width=1280 --height=720 \
    --log="$HOME/weston-hyprland.log" &
weston_pid=$!
cleanup() {
    kill "$weston_pid" 2>/dev/null || true
    wait "$weston_pid" 2>/dev/null || true
}
trap cleanup EXIT

if ! wait_for_socket "$weston_pid" "wayland-hyprland-host"; then
    printf "%s\n" "Weston did not start. Check $HOME/weston-hyprland.log." >&2
    exit 1
fi
export WAYLAND_DISPLAY=wayland-hyprland-host
export XDG_SESSION_TYPE=wayland

if ! protocols=$(wayland-info); then
    printf "%s\n" "Unable to inspect the Weston Wayland session." >&2
    exit 1
fi
case "$protocols" in
    *zwp_linux_dmabuf_v1*) ;;
    *)
        printf "%s\n" "The Weston session has no DMA-BUF support required by Hyprland." >&2
        exit 1
        ;;
esac

Hyprland
'
