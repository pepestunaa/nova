#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
root=$(dirname -- "$script_dir")
manifest=$root/build.zig.zon
zvm_installer_url='https://git.xeondev.com/nyan/zvm/raw/branch/main/install.ps1'
yes=false

case "${1:-}" in
    -y|--yes)
        yes=true
        shift
        ;;
esac
[ "$#" -eq 0 ] || {
    printf 'Unknown setup argument: %s\n' "$1" >&2
    exit 1
}

confirm()
{
    "$yes" && return 0
    [ -r /dev/tty ] || {
        printf 'Cannot ask for confirmation without an interactive terminal.\n' >&2
        return 1
    }
    printf '%s [y/N]: ' "$1" >/dev/tty
    IFS= read -r answer </dev/tty || return 1
    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

require_command()
{
    command -v "$1" >/dev/null 2>&1 || {
        printf "'%s' is required. Install it with your distribution's package manager, then try again.\n" "$1" >&2
        exit 1
    }
}

zvm_bin_dir()
{
    if [ -n "${ZVM_HOME:-}" ]; then
        printf '%s/bin' "$ZVM_HOME"
    elif [ -n "${XDG_DATA_HOME:-}" ]; then
        printf '%s/zvm/bin' "$XDG_DATA_HOME"
    else
        printf '%s/.local/share/zvm/bin' "$HOME"
    fi
}

find_zig()
{
    wanted=$1
    zvm_zig=$(zvm_bin_dir)/zig
    if [ -x "$zvm_zig" ] && [ "$(cd -- "$root" && "$zvm_zig" version 2>/dev/null || true)" = "$wanted" ]; then
        zig_path=$zvm_zig
        return 0
    fi

    candidate=$(command -v zig 2>/dev/null || true)
    if [ -n "$candidate" ] && [ "$(cd -- "$root" && "$candidate" version 2>/dev/null || true)" = "$wanted" ]; then
        zig_path=$candidate
        return 0
    fi
    return 1
}

[ -f "$manifest" ] || {
    printf 'Nova does not contain build.zig.zon.\n' >&2
    exit 1
}
required_version=$(sed -n 's/^[[:space:]]*\.minimum_zig_version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest")
[ -n "$required_version" ] || {
    printf 'build.zig.zon does not declare a literal .minimum_zig_version.\n' >&2
    exit 1
}

if ! find_zig "$required_version"; then
    current_version=''
    current_zig=$(command -v zig 2>/dev/null || true)
    if [ -n "$current_zig" ]; then
        current_version=$($current_zig version 2>/dev/null || true)
    fi
    if [ -n "$current_version" ]; then
        prompt="Found Zig $current_version, but Nova needs $required_version. Install zvm?"
    else
        prompt="Zig $required_version is required. Install zvm?"
    fi
    confirm "$prompt" || {
        printf 'Install Zig %s manually, then run the starter again.\n' "$required_version" >&2
        exit 1
    }

    require_command curl
    require_command tar
    require_command xz
    require_command mktemp
    printf 'Installing zvm...\n' >&2

    installer=$(mktemp)
    log=$(mktemp)
    cleanup()
    {
        rm -f -- "$installer" "$log"
    }
    trap cleanup 0 HUP INT TERM

    if ! curl -fsSL "$zvm_installer_url" -o "$installer" >"$log" 2>&1; then
        cat "$log" >&2
        exit 1
    fi
    if ! sh "$installer" -y >"$log" 2>&1; then
        cat "$log" >&2
        exit 1
    fi

    cleanup
    trap - 0 HUP INT TERM
    hash -r
    find_zig "$required_version" || {
        printf 'zvm completed, but Zig %s is still unavailable.\n' "$required_version" >&2
        exit 1
    }
fi

printf '%s\n' "$zig_path"

