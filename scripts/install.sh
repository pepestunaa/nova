#!/bin/sh
set -eu

repository_url='https://git.xeondev.com/nyan/astralis.git'
branch='main'
project_name='Astralis'
checkout_arg=''
yes=false

fail()
{
    printf '%s\n' "$*" >&2
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --path)
            [ "$#" -ge 2 ] || fail '--path requires a value.'
            checkout_arg=$2
            shift 2
            ;;
        --path=*)
            checkout_arg=${1#*=}
            shift
            ;;
        -y|--yes)
            yes=true
            shift
            ;;
        *)
            fail "Unknown installer argument: $1"
            ;;
    esac
done

require_command()
{
    command -v "$1" >/dev/null 2>&1 ||
        fail "'$1' is required. Install it with your distribution's package manager, then run the installer again."
}

read_tty()
{
    [ -r /dev/tty ] || fail 'Cannot ask for input without an interactive terminal.'
    printf '%s' "$1" >/dev/tty
    IFS= read -r answer </dev/tty || fail 'Could not read from the terminal.'
    printf '%s' "$answer"
}

confirm()
{
    "$yes" && return 0
    answer=$(read_tty "$1 [y/N]: ")
    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

installer_path=$0
case "$installer_path" in
    */*) ;;
    *) installer_path=$(command -v "$installer_path" 2>/dev/null || true) ;;
esac

if [ -n "$installer_path" ] && [ -f "$installer_path" ]; then
    installer_dir=$(CDPATH= cd -- "$(dirname -- "$installer_path")" && pwd -P)
    local_root=$(dirname -- "$installer_dir")
    if [ -d "$local_root/.git" ] &&
        [ -f "$local_root/build.zig.zon" ] &&
        [ -f "$installer_dir/start.sh" ]; then
        printf 'Astralis is already installed at %s.\n' "$local_root"
        if confirm 'Start Astralis from this checkout?'; then
            if [ -t 1 ]; then
                printf '\033[2J\033[3J\033[H'
            fi
            if "$yes"; then
                exec sh "$installer_dir/start.sh" --yes
            fi
            exec sh "$installer_dir/start.sh"
        fi
        exit 0
    fi
fi

normalize_remote()
{
    value=${1%/}
    value=${value%.git}
    printf '%s' "$value"
}

assert_checkout()
{
    checkout=$1
    [ -d "$checkout/.git" ] || fail "'$checkout' already exists and is not an Astralis Git checkout."
    origin=$(git -C "$checkout" remote get-url origin 2>/dev/null) ||
        fail "The checkout at '$checkout' has no readable origin remote."
    [ "$(normalize_remote "$origin")" = "$(normalize_remote "$repository_url")" ] ||
        fail "The checkout at '$checkout' does not use the Astralis repository as its origin."
    current_branch=$(git -C "$checkout" branch --show-current 2>/dev/null) ||
        fail "Could not read the branch for '$checkout'."
    [ "$current_branch" = "$branch" ] ||
        fail "The checkout at '$checkout' is on branch '$current_branch', not '$branch'."
}

require_command git
require_command curl
require_command tar
require_command xz
require_command mktemp

if [ -n "$checkout_arg" ]; then
    selected=$checkout_arg
else
    default_parent=${HOME:-$PWD}
    selected=$(read_tty "Where should Astralis be installed? [$default_parent]: ")
    [ -n "$selected" ] || selected=$default_parent
fi

case "$selected" in
    /*) absolute=$selected ;;
    *) absolute=$PWD/$selected ;;
esac

if [ "$(basename -- "$absolute")" = "$project_name" ]; then
    checkout=$absolute
else
    checkout=$absolute/$project_name
fi

parent=$(dirname -- "$checkout")
mkdir -p -- "$parent" || fail "Could not create '$parent'."
parent=$(cd -- "$parent" && pwd -P) || fail "Could not resolve '$parent'."
checkout=$parent/$(basename -- "$checkout")

needs_clone=true
if [ -e "$checkout" ]; then
    if [ -d "$checkout/.git" ]; then
        assert_checkout "$checkout"
        needs_clone=false
    elif [ ! -d "$checkout" ]; then
        fail "'$checkout' exists and is not a directory."
    elif [ -n "$(ls -A -- "$checkout")" ]; then
        fail "'$checkout' already exists and is not empty."
    fi
fi

if "$needs_clone"; then
    printf '\nAstralis will be installed at:\n    %s\n' "$checkout"
    confirm 'Continue?' || fail 'Installation cancelled.'
    git clone --depth=1 --branch "$branch" --single-branch -- "$repository_url" "$checkout" ||
        fail 'Git could not clone Astralis.'
fi

if "$yes"; then
    zig_path=$(sh "$checkout/scripts/setup.sh" --yes)
else
    zig_path=$(sh "$checkout/scripts/setup.sh")
fi
[ -n "$zig_path" ] || fail 'Astralis setup did not return a Zig executable.'

printf '\n[OK] Astralis is ready at %s\n' "$checkout"
printf 'Start it with:\n    sh "%s/scripts/start.sh"\n' "$checkout"
