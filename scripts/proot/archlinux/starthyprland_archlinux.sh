#!/data/data/com.termux/files/usr/bin/bash

# Start Hyprland in Arch using the same login sequence as the Debian launcher.
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
    printf "%s\n" "Install xorg-xdpyinfo inside Arch before starting Hyprland." >&2
    exit 1
fi

# Check the connection inside Arch rather than relying on a socket file existing.
display_ready=false
for attempt in {1..15}; do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2> "$HOME/hyprland-display.log"; then
        display_ready=true
        break
    fi
    sleep 1
done

if [ "$display_ready" != true ]; then
    printf "%s\n" "Cannot connect to Termux:X11 on $DISPLAY." \
        "Check ~/hyprland-display.log in Arch and ~/termux-x11.log in Termux." >&2
    cat "$HOME/hyprland-display.log" >&2
    exit 1
fi

# Run the nested desktop inside a private D-Bus session.
exec dbus-run-session -- /bin/bash -s << "DESKTOP_SESSION"
set -euo pipefail

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
DESKTOP_SESSION
'
