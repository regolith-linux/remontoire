# Remontoire

## Summary

Remontoire is a small GTK app for presenting keybinding hints in a compact form suitable for tiling window environments interactively on an i3-wm based desktop. It functions by scanning and parsing comments in a specific format from a running instance of i3-wm over IPC.

## Model

Remontoire utilizes the concept of a `category` to group items, `action` to denote the human description, and `keybinding` to define the specific keys corresponding to the action.  The format is designed to be both easily parsable by program but also readable in it's native form by people:

```
## <category> // <action> // <keybinding> ## <reserved for user notes>
```

Text within `<category>`, `<action>`, and `<keybinding>` must not contain the sequences `##`, `//`, or line feeds.

Examples:

```
...
## Navigate // Relative Window // <> ↑ ↓ ← → ##
bindsym $mod+Left focus left
...
```

```
...
## Launch // Application // <> Space ## some extra notes that are ignored by remontoire but maybe of interest to those reading the config file.
bindsym $mod+space exec $i3-wm.program.launcher.app
```

## Usage

```
Usage:
  remontoire [OPTION?]

Help Options:
  -h, --help                           Show help options

Application Options:
  -v, --version                        Display version number
  -s, --socket=<Socket URI>            Socket path for i3
  -c, --file=<Path to config file>     Config file
  -t, --style=<Path to style file>     CSS file

```

Remontoire communicates with i3 to retrieve the active i3 config file.  To determine the socket path on a system running i3:
```bash
$ i3 --get-socketpath
```

Or altogether:
```bash
$ remontoire -s `i3 --get-socketpath`
```

Remontoire can also be passed a file path and will read from that instead of the i3 socket.  In this mode, Remontoire can be used to display keybindings from any file that utilize the comment format.

```bash
$ remontoire -c /etc/something/interesting.conf
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

## Style

You can specify a custom CSS file to change the look of the dialog.

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
