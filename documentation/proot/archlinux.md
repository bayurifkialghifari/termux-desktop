# Install Arch Linux ARM in Termux (PRoot)

This guide sets up Arch, installs your chosen desktop, and explains how to try a basic session. Start with one option: **LXDE**, **Xfce**, **GNOME**, **KDE Plasma**, or **Hyprland**. Configure themes, dotfiles, bars, animations, and other rice settings after the desktop opens successfully.

On Android devices with ARM processors, use **Arch Linux ARM**, which has its own repositories and packages. The instructions below target **aarch64 / ARM64 Termux** without Android root access.

## Choose a desktop

| Desktop | Display path in Termux | Notes for your first attempt |
| --- | --- | --- |
| [LXDE](#lxde) | Directly through Termux:X11 | Start here to check your X11 connection. |
| [Xfce](#xfce) | Directly through Termux:X11 | Another X11 desktop for an initial test. |
| [GNOME](#gnome) | GNOME Shell development mode, depending on version | Experimental in PRoot; a complete session may require systemd services. |
| [KDE Plasma](#kde-plasma) | KWin Wayland nested inside Weston | Test the Plasma shell manually; a full session depends on available services. |
| [Hyprland](#hyprland) | Wayland with compatible GPU and DMA-BUF support | Packages can be installed, but running the compositor in rootless PRoot is not guaranteed. |

Termux:X11 is an **X11** server. Modern Hyprland uses Aquamarine and requires a Wayland session or DRM; `DISPLAY=:0 Hyprland` alone is insufficient. Weston can provide a Wayland session on top of X11, but it does not automatically provide the GPU access Hyprland needs. See [Termux:X11](https://github.com/termux/termux-x11#using-with-proot-environment) and the [Aquamarine backend](https://github.com/hyprwm/aquamarine/blob/main/src/backend/Wayland.cpp).

## 1. Prepare Termux and Termux:X11

Install the [Termux and Termux:X11 apps](../../README.md#first-step), including the Termux:X11 APK. Run the following **in Termux**, before entering Arch:

```bash
pkg update && pkg upgrade
pkg install x11-repo
pkg install proot-distro termux-x11-nightly pulseaudio curl
uname -m
proot-distro --version
```

Continue with the ARM64 instructions below if `uname -m` reports `aarch64`. For `armv7l`, `i686`, or `x86_64`, use a rootfs matching that architecture; do not install the ARM64 rootfs from this example.

## 2. Install Arch

### PRoot-Distro 5 or later

PRoot-Distro 5 installs OCI images or rootfs archives; do not assume version 4's built-in distribution aliases are still available. This example uses an **ARM64 rootfs from the official PRoot-Distro v4.29.0 release** as a starting point, followed by a full upgrade in the next step. This archive is not the latest Arch snapshot. The archive format is supported by [current PRoot-Distro](https://github.com/termux/proot-distro#install--install-a-container), and its checksum comes from the [official version 4 Arch plugin](https://github.com/termux/proot-distro/blob/v4.32.0/distro-plugins/archlinux.sh).

Run **in Termux**:

```bash
curl -fL -o archlinux-aarch64-pd-v4.29.0.tar.xz \
  https://github.com/termux/proot-distro/releases/download/v4.29.0/archlinux-aarch64-pd-v4.29.0.tar.xz

printf '%s  %s\n' \
  '08d74365213e647c558e561b0a2a7afb6fa3dfe345a1994c62ccac5af1a1cdc6' \
  'archlinux-aarch64-pd-v4.29.0.tar.xz' | sha256sum -c - &&
  proot-distro install ./archlinux-aarch64-pd-v4.29.0.tar.xz --name archlinux
```

Continue only if the checksum reports `OK` and installation succeeds. All examples below use the container name `archlinux`. If that container already exists, log into your existing installation instead.

### PRoot-Distro 4

If you still use version 4 and `proot-distro list` shows the `archlinux` plugin, use this method **instead of** installing the archive above:

```bash
proot-distro install archlinux
```

### Log in as the container's root user

Run **in Termux**:

```bash
proot-distro login archlinux --shared-tmp
```

`--shared-tmp` shares the Termux:X11 socket with Arch. Root inside PRoot is the container's root user, not Android root access.

## 3. Update Arch and create a user

Run every command in this section **inside Arch as root**:

```bash
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu
pacman -S --needed dbus mesa mesa-utils xorg-xauth xorg-xdpyinfo \
  ttf-dejavu nano shadow
dbus-uuidgen --ensure=/etc/machine-id
```

Do not install a desktop if `pacman -Syu` fails. Arch requires full upgrades; avoid running `pacman -Sy` followed by an ordinary package installation. Keyring initialization follows the [Arch Linux ARM instructions](https://archlinuxarm.org/platforms/armv8/generic).

Create the `wowo` user once, then set its password:

```bash
useradd -m -s /bin/bash wowo
passwd wowo
```

Install packages through a root login to the container. Run desktop sessions as `wowo`, so you do not need to add sudo rules. If you choose another username, replace `wowo` in the login commands below.

## 4. Prepare the display before trying a desktop

Leave Arch with `exit`. Run the following **in Termux**, once for your testing session:

```bash
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp \
  auth-ip-acl=127.0.0.1 listen=127.0.0.1
termux-x11 :0 > "$HOME/termux-x11.log" 2>&1 &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
```

If PulseAudio has already loaded the TCP module, loading it again may report a failure; check with `pactl list short modules`. Do not start a second X11 server on display `:0` while the previous server is running.

After installing your chosen desktop's packages, log in as your user **from Termux**:

```bash
proot-distro login archlinux --user wowo --shared-tmp
```

Run the following **inside Arch as wowo**, each time you open a new shell to try a desktop:

```bash
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export XDG_RUNTIME_DIR="$HOME/.local/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS
xdpyinfo >/dev/null && echo 'Termux:X11 connection OK'
```

Wait for the X11 server to become ready if the check fails. The runtime directory belongs in your user's home; do not run `chmod 700 /tmp` because `/tmp` is shared with Termux.

## LXDE

Install **inside Arch as root**, using `proot-distro login archlinux` from Termux:

```bash
pacman -Syu --needed lxde-common lxsession lxpanel openbox pcmanfm lxterminal
exit
```

Log in as `wowo` and prepare the display as described in step 4. Then run **inside Arch as wowo**:

```bash
dbus-run-session -- startlxde
```

LXDE connects directly to Termux:X11. To finish, log out through the desktop; once the command returns to the terminal, run `exit` to leave Arch.

## Xfce

Install **inside Arch as root**:

```bash
pacman -Syu --needed xfce4 xfce4-terminal
exit
```

Log in as `wowo` and prepare the display as described in step 4. Then run **inside Arch as wowo**:

```bash
dbus-run-session -- xfce4-session
```

Xfce connects directly to Termux:X11. Log out to end the session, then run `exit` to leave Arch.

## GNOME

Install **inside Arch as root**:

```bash
pacman -Syu --needed gnome-shell gnome-control-center nautilus \
  gnome-terminal gnome-tweaks pipewire xorg-xwayland
exit
```

This installs the basic GNOME components without a display manager. Check the shell's available options **inside Arch as wowo**, after step 4:

```bash
gnome-shell --version
gnome-shell --help
```

Recent GNOME releases no longer provide the old X11 session. Mutter 51 provides **`--devkit`** for testing through a viewer; older versions may offer `--nested`. Choose an option shown by `--help` instead of forcing `gnome-shell --x11`. The devkit option is documented in the [Mutter 51 source](https://github.com/GNOME/mutter/blob/51.1/src/core/meta-context-main.c).

If `--devkit` is available, try development mode **as wowo**:

```bash
dbus-run-session -- bash -c '
  export LIBGL_ALWAYS_SOFTWARE=1
  export GALLIUM_DRIVER=llvmpipe
  pipewire > "$HOME/gnome-pipewire.log" 2>&1 &
  pipewire_pid=$!
  trap "kill $pipewire_pid 2>/dev/null" EXIT
  gnome-shell --devkit
'
```

For older versions that explicitly list `--nested` in their help output, an alternative basic test is:

```bash
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
  dbus-run-session -- gnome-shell --wayland --nested
```

Development mode is experimental on Android/PRoot and does not provide a complete GNOME session. If PipeWire, the viewer, or session services fail, save the error and stop at package installation. PRoot does not run a systemd init environment like a regular Linux installation; do not enable GDM or delete `login1` files to force the session to start. See the [PRoot-Distro limitations](https://github.com/termux/proot-distro#limitations).

## KDE Plasma

Install **inside Arch as root**:

```bash
pacman -Syu --needed plasma-desktop plasma-workspace kwin konsole \
  dolphin weston xorg-xwayland
exit
```

Plasma X11 packages and sessions vary between releases. This guide tries **KWin Wayland nested inside Weston**, avoiding a dependency on `startplasma-x11` being available. The windowed Wayland and `--exit-with-session` options are present in the [KWin source](https://github.com/KDE/kwin/blob/Plasma/6.8/src/main_wayland.cpp).

After logging in as `wowo` and following step 4, start Weston **inside Arch**:

```bash
weston --backend=x11 --renderer=pixman \
  --socket=wayland-weston --width=1280 --height=720 \
  --log="$HOME/weston.log" &
weston_pid=$!
```

Weston opens a window in Termux:X11. Wait until its socket is ready:

```bash
test -S "$XDG_RUNTIME_DIR/wayland-weston" && echo 'Weston socket ready'
```

Continue only after the check succeeds. Then run:

```bash
export WAYLAND_DISPLAY=wayland-weston
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
  dbus-run-session -- kwin_wayland \
  --wayland-display=wayland-weston --socket=wayland-plasma \
  --width=1280 --height=720 --xwayland \
  --exit-with-session=plasmashell
```

This manually tests KWin and the Plasma shell without SDDM or a complete systemd session. Features that depend on session services may be limited. Software rendering uses the CPU, so start at a low resolution. The X11 backend and Pixman renderer are documented by [Weston](https://wayland.pages.freedesktop.org/weston/toc/running-weston.html).

When finished, stop the session from its launching terminal with `Ctrl+C` if it is still running. Stop Weston from the shell that holds its PID:

```bash
kill "$weston_pid"
unset WAYLAND_DISPLAY
exit
```

## Hyprland

Install **inside Arch as root**:

```bash
pacman -Syu --needed hyprland foot xorg-xwayland wl-clipboard \
  weston wayland-utils
pacman -Q hyprland aquamarine
exit
```

The [aarch64 Hyprland package](https://archlinuxarm.org/packages/aarch64/hyprland) is available in the Arch Linux ARM repositories, so you do not need to start by building from the AUR. Pacman installs Aquamarine as a dependency. This completes package installation; leave dotfiles and rice scripts for later.

### Requirements before trying to launch Hyprland

Modern Hyprland does not provide a direct X11 backend. Aquamarine's Wayland backend needs the **`zwp_linux_dmabuf_v1`** protocol and a usable DRM render node. Weston with `--renderer=pixman` from the KDE example provides a basic Wayland display but **does not meet Hyprland's GPU requirements**. See the [Wayland backend implementation](https://github.com/hyprwm/aquamarine/blob/main/src/backend/Wayland.cpp) and [allocator setup](https://github.com/hyprwm/aquamarine/blob/main/src/backend/Backend.cpp).

In rootless Android PRoot, `/dev/dri/renderD*` is often unavailable or unusable. Installing Arch does not automatically expose the Android GPU as a Linux DRM device. `WLR_BACKENDS=x11` from older Hyprland tutorials does not add an X11 backend to Aquamarine either.

If you already have a Wayland compositor with compatible GPU rendering, run these checks **inside Arch as wowo**, with `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` pointing to that session:

```bash
printf 'Runtime: %s\nWayland: %s\n' "$XDG_RUNTIME_DIR" "$WAYLAND_DISPLAY"
wayland-info
ls -l /dev/dri/renderD*
```

Continue only if the active compositor advertises `zwp_linux_dmabuf_v1` and your user can open the render node with a compatible driver. Running Weston or `glxinfo` with llvmpipe alone does not establish those requirements. If they are not met, you can try **package installation** on this setup; testing the Hyprland GUI requires another GPU path.

Once the requirements are met, try the default configuration before ricing:

```bash
dbus-run-session -- Hyprland 2>&1 | tee "$HOME/hyprland-start.log"
```

`Missing protocols`, `no allocator available`, or failure to open DRM indicate a backend/GPU problem. Save the log to determine your next step; changing themes or dotfiles will not resolve it.

## Try desktops one at a time and troubleshoot

To try another desktop, finish your current session, leave Arch, then log in as the container's root user to install the next desktop's packages. Log in again as `wowo` and repeat step 4. Desktop packages can coexist in one container; run **one desktop session at a time**.

- **`cannot open display` / `unable to open display`:** check that `termux-x11 :0` is running, your login uses `--shared-tmp`, and `DISPLAY=:0` is set. Run `xdpyinfo` again.
- **Black screen in Termux:X11:** after stopping the desktop, stop the old X11 server from Termux with `pkill -f termux-x11`, then start `termux-x11 :0 -legacy-drawing` and reopen the Termux:X11 app. This option follows the [official troubleshooting instructions](https://github.com/termux/termux-x11#running-graphical-applications).
- **No audio:** check `pactl list short modules` in Termux for the TCP module and verify `PULSE_SERVER=tcp:127.0.0.1:4713` in your Arch shell.
- **`XDG_RUNTIME_DIR` errors:** repeat runtime directory setup as `wowo`; use the same directory and user for the compositor and its clients.
- **Signature/keyring errors during upgrades:** as the container's root user, repeat `pacman-key --init` and `pacman-key --populate archlinuxarm`. If the old keyring does not recognize new package signing keys, try the following limited keyring update and immediately complete the full upgrade:

  ```bash
  pacman -Sy --needed archlinuxarm-keyring && pacman -Su
  ```

  Do not install other packages between these commands. If the upgrade still fails, save the full error; do not disable signature checks with `SigLevel = Never`.

This guide has not been tested directly on an Android device. Commands and options were checked against upstream documentation/source on **November 12, 2026**; GNOME, Plasma, and especially Hyprland depend on package versions, services, and device drivers.
