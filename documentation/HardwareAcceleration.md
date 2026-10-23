# Hardware Acceleration in Termux (Proot)

In this guide, we will explore how to enable hardware acceleration in Termux when using Proot-based distributions. Hardware acceleration can significantly improve the performance of graphical applications by leveraging the device's GPU.

<br>

---

---

<br>

## 🏁 Install Required Packages <a name=install-required-packages></a>

```bash
pkg install mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android
```

## ⚙️ Initialize GUI in Termux

Before login to proot and use hardware acceleration you need to start the graphical server:

- Vulkan

```bash
MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
```

- OpenGL (VIRGL):

```bash
virgl_test_server_android &
```

## ⚔️ Run the Desktop with Hardware Acceleration

Run the Desktop with my script (if you do manually instead of using my script, take in to account that you need to share the tmp dir to make it work):

```
./startxfce4_debian.sh
```

Once in the Desktop when you want to run a program with hardware acceleration use this before:

- For VIRGL and ZINK (depending on the graphic server you started in Termux it will use ZINK or VIRGL):

```
GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 program
```
