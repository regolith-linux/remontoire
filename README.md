# Remontoire

## Summary

Remontoire is a small GTK app for presenting keybinding hints in a compact form suitable for tiling window environments interactively on an i3-wm based desktop. It functions by scanning and parsing comments in a specific format from a running instance of i3-wm over IPC.

## Model

Remontoire utilizes the concept of a `category` to group items, `action` to denote the human description, and `keybinding` to define the specific keys corresponding to the action.  The format is designed to be both easily parsable by program but also readable in it's native form by people:

```
## <category> // <action> // <keybinding> ## <reserved for user notes>
```

Text within `<category>`, `<action>`, and `<keybinding>` must not contain the sequences `##`, `//`, or line feeds.

Example:

```
## Launch // Application // <> Space ## some extra notes that are ignored by remontoire but maybe of interest to those reading the config file.
```

## Usage

```
usage: remontoire <i3 socket path>
```

Remontoire communicates with i3 to retrieve the active i3 config file.  To determine the socket path on a system running i3:
```bash
$ i3 --get-socketpath
```

Or altogether:
```bash
$ remontoire `i3 --get-socketpath`
```

Once executed Remontoire will display a sticky floating window on the right-center of the primary monitor. Upon first launch, all categories are collapsed.  User selections to open categories are persisted across instantiations of the program.

## Configuration

Remontoire utilizes GLib settings to store configuration using the namespace `org.regolith-linux.remontoire`.  The following settings are available for user customization:

### Window Position
```
window-position <north|south|east|west>
```

#### Example

```bash
$ gsettings set org.regolith-linux.remontoire window-position "west"
```

### Padding

Vertical and horizontal padding can be specified independently, allowing for bars or other UI widgets to be accounted for when placing the window.  The keys for padding are `window-padding-width` and `window-padding-height` and the value units are pixels.

#### Example

```bash
$ gsettings set org.regolith-linux.remontoire window-padding-width 10
$ gsettings set org.regolith-linux.remontoire window-padding-height 20
```

## Install Package

### Ubuntu

Remontoire is available from the Regolith Linux `unstable` PPA:

```
$ sudo add-apt-repository ppa:regolith-linux/unstable
$ sudo apt install remontoire
```

## Build from Source

Meson, Vala, [Grelier](https://github.com/regolith-linux/grelier) and Gtk+ libraries are required to build.  After downloading sources, from within the project root, execute the following:

```
$ meson build
$ cd build
$ ninja
```
