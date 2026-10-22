#!/bin/sh
# An option that needs a value but has none is reported, with exit status 1.
# usage: option_without_value.sh <remontoire>
remontoire=$1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf '## Cat // Action // <Super> a ##\n' > "$tmp/config"

failures=0
check() {
    option=$1
    shift
    "$remontoire" "$@" > "$tmp/out" 2> "$tmp/err" < /dev/null
    status=$?
    if [ "$status" -eq 1 ] && grep -q "option $option requires a value" "$tmp/err" && ! grep -q CRITICAL "$tmp/err"; then
        echo "ok - $option without a value"
    else
        echo "not ok - $option without a value: exit status $status, stderr: $(head -c 300 "$tmp/err")"
        failures=$((failures + 1))
    fi
}

check -s -s
check -c -c
check -t -c "$tmp/config" -t
check -p -c "$tmp/config" -p
check -p -c "$tmp/config" -p -t /dev/null
check -s -c "$tmp/config" -s -v
check -c -c -h

[ "$failures" -eq 0 ]
