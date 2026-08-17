#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
root=$(dirname -- "$script_dir")

yes=false
case "${1:-}" in
    -y|--yes)
        yes=true
        shift
        ;;
esac
if [ "${1:-}" = "--" ]; then
    shift
fi

if "$yes"; then
    zig_path=$(sh "$script_dir/setup.sh" --yes)
else
    zig_path=$(sh "$script_dir/setup.sh")
fi

cd -- "$root"
if [ "$#" -gt 0 ]; then
    exec "$zig_path" build -Doptimize=ReleaseSafe serve-all -- "$@"
fi
exec "$zig_path" build -Doptimize=ReleaseSafe serve-all

