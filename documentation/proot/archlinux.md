# Proot Arch Linux ARM Installation

- [Install Termux + Termux X11](../../README.md#first-step)
- [Install Required Termux Packages](../../README.md#install-required-termux-packages)

<br>

---

---

<br>

## 🏁 First Step <a name=install-archlinux></a>

Install Arch and log in using the following commands **in Termux**. This example is for PRoot-Distro 5 or later:

```bash
pd --version

curl -fL -o archlinux-aarch64-pd-v4.29.0.tar.xz \
  https://github.com/termux/proot-distro/releases/download/v4.29.0/archlinux-aarch64-pd-v4.29.0.tar.xz

printf '%s  %s\n' \
  '08d74365213e647c558e561b0a2a7afb6fa3dfe345a1994c62ccac5af1a1cdc6' \
  'archlinux-aarch64-pd-v4.29.0.tar.xz' | sha256sum -c - &&
  pd install ./archlinux-aarch64-pd-v4.29.0.tar.xz --name archlinux

pd login archlinux --shared-tmp
```

Continue after the checksum reports `OK`. This [official PRoot-Distro rootfs](https://github.com/termux/proot-distro/blob/v4.32.0/distro-plugins/archlinux.sh) needs the full upgrade below.

Using PRoot-Distro 4?

Use its built-in Arch plugin instead of the archive above:

```bash
pd install archlinux
pd login archlinux --shared-tmp
```

<br>

---

---

<br>

## ⚙️ Update nameserver

Update the nameserver inside Arch as root:

```bash
echo -e "nameserver 1.1.1.1" > /etc/resolv.conf
```

<br>

---

---

<br>

## ⚙️ Initialize Keyring

Run the following commands **inside Arch as root**:

```bash
pacman-key --init
pacman-key --populate archlinuxarm
```

<br>

---

---

<br>

## 🖥️ Update Repository and install packages

Update Arch and install the required packages **as root**:

```bash
pacman -Syu \
&& pacman -S --needed sudo dbus mesa mesa-utils xorg-xauth xorg-xdpyinfo \
  ttf-dejavu nano shadow \
&& dbus-uuidgen --ensure=/etc/machine-id
```

Package signing errors?

Update the keyring, then immediately complete the full upgrade:

```bash
pacman -Sy --needed archlinuxarm-keyring && pacman -Su
```

Do not install other packages between these commands or disable signature checks.

<br>

---

---

<br>

## ⚔️ Add User

Create the user that the start scripts will use:

```bash
useradd -m -s /bin/bash wowo
passwd wowo
```

Add the user to sudoers:

```bash
echo "wowo ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Add the user to the wheel group:

```bash
usermod -aG wheel wowo
```

Test the user and sudo, then return to the root shell:

```bash
su - wowo
whoami
sudo whoami
exit
```

The scripts default to `wowo`. Pass another username as the first script argument if needed.

<br>

---

---

<br>

## Select One Desktop Environment to install

Run your chosen command **inside Arch as root**.

Xfce4 Desktop Environment <a name=xfce></a>

```bash
pacman -Syu --needed xfce4 xfce4-terminal
```

<br>

KDE Plasma Desktop Environment <a name=kde-plasma></a>

```bash
pacman -Syu --needed plasma-desktop plasma-workspace kwin konsole \
  dolphin weston xorg-xwayland
```

<br>

LXDE Desktop Environment <a name=lxde></a>

```bash
pacman -Syu --needed lxde-common lxsession lxpanel openbox pcmanfm lxterminal
```

<br>

GNOME Desktop Environment <a name=gnome></a>

```bash
pacman -Syu --needed gnome-shell gnome-control-center nautilus \
  gnome-terminal gnome-tweaks pipewire xorg-xwayland
```

GNOME development mode is experimental in PRoot.

<br>

Hyprland Window Manager <a name=hyprland></a>

```bash
pacman -Syu --needed hyprland foot xorg-xwayland wl-clipboard \
  weston wayland-utils
```

Hyprland needs GPU/DRM and DMA-BUF support. Its start script checks these requirements; rootless Android devices may not support them.

<br>

---

---

<br>

## ⬇️ Script to start Desktop Environment

Leave Arch, then download your chosen script **in Termux**:

```bash
exit
```

- Xfce4

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/archlinux/startxfce_archlinux.sh
```

<br>

- KDE Plasma

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/archlinux/startkde_archlinux.sh
```

<br>

- LXDE

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/archlinux/startlxde_archlinux.sh
```

<br>

- GNOME

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/archlinux/startgnome_archlinux.sh
```

<br>

- Hyprland

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/archlinux/starthyprland_archlinux.sh
```

<br>

---

---

<br>

## Compatibility notes

- Xfce4 and LXDE use Termux:X11 directly.
- KDE runs a basic Plasma shell inside Weston with software rendering.
- GNOME selects `--devkit` or `--nested` when available; it does not start a complete systemd session.
- Hyprland uses GPU-rendered Weston and requires a usable DRM render node plus `zwp_linux_dmabuf_v1`. Pixman/llvmpipe alone is insufficient.
- Finish one desktop session before starting another. Ricing is left for later.

References: [PRoot-Distro](https://github.com/termux/proot-distro#limitations), [Termux:X11](https://github.com/termux/termux-x11#using-with-proot-environment), [Aquamarine](https://github.com/hyprwm/aquamarine/blob/main/src/backend/Wayland.cpp).

The launchers have not been tested directly on an Android device.
