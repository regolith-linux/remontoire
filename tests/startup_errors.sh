#!/bin/sh
# remontoire exits with status 1 and a message, instead of aborting, when the
# window manager socket, the config file or the stylesheet cannot be used.
# usage: startup_errors.sh <remontoire> <data dir>
remontoire=$1
data_dir=$2

command -v xvfb-run >/dev/null || { echo "xvfb-run not found, skipping"; exit 77; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
glib-compile-schemas --targetdir="$tmp" "$data_dir" || exit 1
export GSETTINGS_SCHEMA_DIR="$tmp" GSETTINGS_BACKEND=memory
printf '## Cat // Action // <Super> a ##\n' > "$tmp/config"
printf 'window { colr: red; }\n' > "$tmp/bad.css"

failures=0
check() {
    name=$1
    shift
    # some versions of xvfb-run send the program's stderr to stdout
    xvfb-run -a "$remontoire" "$@" > "$tmp/output" 2>&1
    status=$?
    if [ "$status" -eq 1 ] && grep -q "Failed to start" "$tmp/output"; then
        echo "ok - $name"
    else
        echo "not ok - $name: exit status $status, output: $(head -c 300 "$tmp/output")"
        failures=$((failures + 1))
    fi
}

check "no window manager at the socket" -s "$tmp/no-such.sock"
check "config path is a directory" -c "$tmp"
check "invalid stylesheet" -c "$tmp/config" -t "$tmp/bad.css"

[ "$failures" -eq 0 ]
