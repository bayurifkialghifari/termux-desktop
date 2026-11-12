# Proot Wine Installation

- [Install Debian + Desktop](debian.md)
- [Install Required Termux Packages](../../README.md#install-required-termux-packages)

<br>

---

---

<br>

## 🏁 First Step <a name=install-wine></a>

Start your Debian desktop, then log in from another Termux session:

```bash
pd login debian --shared-tmp
```

<br>

---

---

<br>

## 🖥️ Update Repository and install packages

Run these commands inside Debian as root:

```bash
apt update && apt upgrade -y \
&& apt install -y libwine ca-certificates gnupg xz-utils
```

<br>

---

---

<br>

## ⚙️ Install Box64

Add the Box64 repository and install the Android build:

```bash
install -d -m 755 /etc/apt/keyrings
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/box64.gpg
chmod 644 /etc/apt/keyrings/box64.gpg

echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/box64.gpg] https://ryanfortner.github.io/box64-debs/debian ./' \
  > /etc/apt/sources.list.d/box64.list

apt update && apt install -y box64-android
box64 --version
```

<br>

---

---

<br>

## ⬇️ Install Wine

Switch to `wowo` and download Wine 11.0 WoW64:

```bash
su - wowo
cd ~
wget -4 https://github.com/Kron4ek/Wine-Builds/releases/download/11.0/wine-11.0-amd64-wow64.tar.xz

printf '%s  %s\n' \
  '39574efa1132c3ca0d5c77dd2eddbe4a49cca0d6cc2c290ff4924493a1c40314' \
  'wine-11.0-amd64-wow64.tar.xz' | sha256sum -c - &&
  tar -xf wine-11.0-amd64-wow64.tar.xz
```

<br>

---

---

<br>

## ⚔️ Create Wine Launcher

Create the `wine` command as `wowo`:

```bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/wine" <<'EOF'
#!/bin/bash
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-box64}"
export WINEARCH=win64
export BOX64_NOBANNER=1
export BOX64_PATH="$HOME/wine-11.0-amd64-wow64/bin"
export BOX64_LD_LIBRARY_PATH="$HOME/wine-11.0-amd64-wow64/lib/wine/x86_64-unix"
exec box64 "$HOME/wine-11.0-amd64-wow64/bin/wine" "$@"
EOF
chmod +x "$HOME/.local/bin/wine"

echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
```

<br>

---

---

<br>

## 🍷 Configure Wine

Initialize Wine and open its settings:

```bash
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
wine --version
wine wineboot --init
wine winecfg
```

<br>

---

---

<br>

## 🚀 Run Windows Programs

Try Notepad, then run your own installer:

```bash
wine notepad
wine "$HOME/Downloads/setup.exe"
```

<br>

---

---

<br>

## Compatibility notes

- This setup is for Debian ARM64. Wine WoW64 runs through Box64; 32-bit app support is experimental.
- Games may need [Hardware Acceleration](../HardwareAcceleration.md).
- This guide has not been tested directly on an Android device.

Based on [Ivon's guide](https://ivonblog.com/en-us/posts/termux-proot-box86-box64/), using the current [Box64 Wine method](https://github.com/ptitSeb/box64/blob/main/docs/WINE.md) and [Wine 11.0 builds](https://github.com/Kron4ek/Wine-Builds/releases/tag/11.0).
