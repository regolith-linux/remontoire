# Remontoire

## Summary

<table><tr><td>
<p>Remontoire is a small (~71Kb) GTK app for presenting keybinding hints in a compact form suitable for tiling window environments.  It is intended for use with the i3 window manager but it's also able to display keybindings from any suitably formatted config file.</p>

<p>The program functions by scanning and parsing comments in a specific format (described directly below), then displaying them in a one-layer categorized list view.  The program stores the state of which sections are expanded, allowing for use on screens with limited resolution.</p>
</td><td><img src="https://regolith-linux.org/regolith-site-r14-beta/docs/reference/releases/regolith-remontoire-screenshot-131.png"/>
</td></tr></table>

## Model

Remontoire utilizes the concept of a `category` to group items, `action` to denote the human description, and `keybinding` to define the specific keys corresponding to the action.  The format is designed to be both easily parsable by program but also readable in it's native form by people:

```
## <category> // <action> // <keybinding> ## <reserved for user notes>
```

Text within `<category>`, `<action>`, and `<keybinding>` must not contain the sequences `##`, `//`, or line feeds.

Examples:

```
...
## Navigate // Relative Window // <Super> ↑ ↓ ← → ##
bindsym $mod+Left focus left
...
```

```
...
## Launch // Application // <Super> Space ## some extra notes that are ignored by Remontoire but maybe of interest to those reading the config file.
bindsym $mod+space exec $i3-wm.program.launcher.app
```

Any line that doesn't contain the structure listed here will be ignored.

## Usage

```
Usage:
  remontoire [OPTION?]

Help Options:
  -h, --help                           Show help options

Application Options:
  -v, --version                        Display version number
  -s, --socket=<Socket URI>            Socket path for i3
  -c <Path to config file>             Config file
  -i <Read from standard input>        Read from standard input
  -t <Path to style file>              CSS file
  -p <comment line prefix>             Prefix of comment line

```

With `-s`, Remontoire communicates with i3 via domain sockets to retrieve the active i3 config file.  To determine the socket path on a system running i3:
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

As a third option to provide your config files, Remontoire can read from STDIN. Use this option
if you want to pass in the contents of multiple config files.

Once executed Remontoire will display a sticky floating window on the right-center of the primary monitor. Upon first launch, all categories are collapsed.  User selections to open categories are persisted across instantiations of the program.

### Toggle

It is suggested to use a small shell script to allow the dialog to be toggled on and off with a hotkey.  Here is one such script from Regolith:

```
#!/bin/bash
# If remontoire is running, kill it.  Otherwise start it.

remontoire_PID=$(pidof remontoire)

if [ -z "$remontoire_PID" ]; then
    /usr/bin/remontoire -s $(printenv I3SOCK) &
else
    kill $remontoire_PID
fi
```

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

You can specify a custom CSS file to change the look of the dialog.  The built-in CSS as of version 1.3.0:

```css
.window {
  margin: 4px;
}

*:selected {
  background-color: @theme_bg_color;
  color: @theme_text_color;
}

.category {
  padding-top: 2px;
  padding-bottom: 2px;
  font-weight: bold;
  font-size: .95em;
  color: @theme_unfocused_fg_color;
}

.action {
  padding-right: 10px;
  padding-left: 15px;
  font-weight: lighter;
}

.error {
  padding: 15px;
  font-size: 1.2em;
  font-weight: bold;
}

.metakey {
  font-family: monospace;
  font-weight: normal;
  background-color: @insensitive_bg_color;
  border: 1px solid;
  border-color: @insensitive_base_color;
  color: @theme_unfocused_fg_color;

  padding: 2px;
  margin: 2px;
  font-size: .9em;
}

.rangekey {
  font-family: monospace;
  font-weight: normal;
  background-color: @insensitive_bg_color;
  border: 1px solid;
  border-color: @insensitive_base_color;
  color: @theme_unfocused_fg_color;

  padding: 2px;
  margin: 2px;
  font-size: .9em;
}

.key {
  font-family: monospace;
  font-weight: normal;
  background-color: @insensitive_bg_color;
  border: 1px solid;
  border-color: @insensitive_base_color;
  color: @theme_unfocused_fg_color;

  padding: 2px;
  margin: 2px;
  font-size: .9em;
}

.detail {
  margin: 2px;
}
```

## Using Remontoire to view keybindings for arbitrary config files

Since Remontoire parses comments and not actual keybindings, it can be used as a keybinding viewer for any app that stores keybindings in plain text and supports comments, like Sway or Vim. Use the `-c` or  `-i` options documented above to supply the config files. If config doesn't use `#` as a comment prefix, you use the `-p` option to supply comment prefix to go immediately before '##'. Here's an example of parsing a comment using Vim's quote character as a prefix:

    echo '"## Category // Description // <Super> J ##' | remontoire -i -p '"'

## Install Package

### Ubuntu

Remontoire is available from the Regolith Linux `stable` PPA:

```
$ sudo add-apt-repository ppa:regolith-linux/stable
$ sudo apt install remontoire
```

### openSUSE

Remontoire is available from the X11:Utilities devel project:

```
$ sudo zypper ar -f obs://X11:Utilities X11Utilities
$ sudo zypper ref
$ sudo zypper in remontoire
```

### Fedora

Remontoire is available in [X3MBoy's Copr](https://copr.fedorainfracloud.org/coprs/x3mboy/remontoire/). Install is available for Fedora 40, 41, 42 and rawhide:

```
sudo dnf copr enable x3mboy/remontoire
sudo dnf install remontoire
```

## Build from Source

Meson, Vala and Gtk+ libraries are required to build.  After downloading sources, from within the project root, execute the following:

```bash
$ meson build
$ cd build
$ ninja
$ src/remontoire -c <path to your config>
... or ...
$ src/remontoire -s `i3 --get-socketpath`
```
