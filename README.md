# Remontoire

A shortcut dialog UI for Regolith that is intended to assist in the learning of keybindings.  The UI is designed for i3-wm in that it positions itself on the screen without window decoration, is always on top of z-order, and is sticky to all workspaces.

# Status

Remontoire is in testing with the goal of being a general-purpose shortcut viewer for i3 and IPC compatible WMs.

## Future Work

* Nicer UI for keybindings using keys similar to the Gtk+ Shortcuts dialog.
* ~~Dynamically read and parse i3-wm keybindings rather than hardcode.~~
* Allow user to change position on screen.

# Usage

## Build

Meson, Vala, [Grelier](https://github.com/regolith-linux/grelier) and Gtk+ libraries are required to build.

```
$ meson build
$ cd build
$ ninja
```

## Run

```
$ src/remontoire
```
