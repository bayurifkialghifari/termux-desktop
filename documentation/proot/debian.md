# Proot Debian Installation

- [Install Termux + Termux X11](../../README.md#-first-step)
- [Install Required Termux Packages](../../README.md#-install-required-termux-packages)

<br>

---

---

<br>

## 🏁 First Step <a name=install-debian></a>

Install debian and login to it using the following command:

```bash
pd install debian
pd login debian
```

<br>

---

---

<br>

## ⚙️ Update nameserver

Update nameserver using the following command:

```bash
echo -e "nameserver 1.1.1.1" > /etc/resolv.conf
```

<br>

---

---

<br>

## 🖥️ Update Repository and install packages

Update and upgrade the repository and install required packages using the following command:

```bash
apt update && apt upgrade -y \
&& apt install -y sudo wget git curl adduser nano
```

<br>

---

---

<br>

## ⚔️ Add User

Add a new user to the system using the following command:

```bash
adduser wowo
```

Add user to sudoers file using the following command:

```bash
echo "wowo ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Add user to sudo group using the following command:

```bash
usermod -aG sudo wowo
```

Test the new user by switching to it using the following command:

```bash
su - wowo
whoami
sudo whoami
```

<br>

---

---

<br>

## Select One Desktop Environment to install

Xfce4 Desktop Environment

```bash
sudo apt install -y xfce4
```

Lxde Desktop Environment

```bash
sudo apt install -y lxde
```

Cinamon Desktop Environment

```bash
sudo apt install -y cinnamon
```

Gnome Desktop Environment

```bash
sudo apt install gnome gnome-shell gnome-terminal gnome-tweaks gnome-software nautilus gnome-shell-extension-manager gedit gnupg2 dbus-x11 -y
```

```bash
for file in $(find /usr -type f -iname "*login1*"); do rm -rf $file
done
```

KDE Plasma Desktop Environment

```bash
sudo apt install kde-plasma-desktop -y
```

<br>

---

---

<br>

## ⬇️ Script to start Desktop Environment

- Xfce4

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/refs/heads/master/scripts/proot/debian/startxfce_debian.sh
```

- Lxde

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/debian/startlxde_debian.sh
```

- Cinamon

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/debian/startcinamon_debian.sh
```

- Gnome

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/debian/startgnome_debian.sh
```

- KDE Plasma

```bash
wget -4 https://raw.githubusercontent.com/bayurifkialghifari/termux-desktop/master/scripts/proot/debian/startkde_debian.sh
```
