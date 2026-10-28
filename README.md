# Termux Desktops

Collection of scripts to install and run desktop environments in Termux.

<br>

---

---

<br>

## 🏁 First Step <a name=first-step></a>

Install Termux and Termux X11 from Github Release page:

- [Termux](https://github.com/termux/termux-app/releases)
- [Termux X11](https://github.com/termux/termux-x11/releases)

<br>

---

---

<br>

## 🖥️ Install Required Termux Packages <a name=install-required-termux-packages></a>

```bash
pkg update \
&& pkg upgrade \
&& pkg install x11-repo tur-repo pulseaudio proot-distro wget git \
&& pkg install termux-x11-nightly
```

<br>

---

---

<br>

## ⚔️ Install Distro

Select One of the following distros to install:

1. [Proot Distro](documentation)
    - [Debian](documentation/proot/debian.md)

<br>

---

---

<br>

## 🚀 Hardware Acceleration <a name=hardware-acceleration></a>

Hardware acceleration is not active by default in Termux. In order to enable it, you need to follow the instructions in the guide.

[Hardware Acceleration](documentation/HardwareAcceleration.md)

Inspired by [Droidmaster](https://github.com/LinuxDroidMaster/Termux-Desktops)
