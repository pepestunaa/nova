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

fail()
{
    printf '%s\n' "$*" >&2
    exit 1
}

[ "$#" -eq 0 ] || fail "Unknown update argument: $1"

confirm()
{
    "$yes" && return 0
    [ -r /dev/tty ] || fail 'Cannot ask for confirmation without an interactive terminal.'
    printf '%s [y/N]: ' "$1" >/dev/tty
    IFS= read -r answer </dev/tty || fail 'Could not read from the terminal.'
    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

[ -d "$root/.git" ] || fail 'update.sh must be run from an Nova Git checkout.'
command -v git >/dev/null 2>&1 || fail 'Git is required to update Nova.'

changes=$(git -C "$root" status --porcelain=v1 --untracked-files=all) ||
    fail 'Could not inspect the Nova checkout.'
customized_configs=''
blocking_changes=''

if [ -n "$changes" ]; then
    while IFS= read -r line; do
        status=$(printf '%.2s' "$line")
        changed_path=${line#???}
        case "$status:$changed_path" in
            ' M:servers/game/config.zon'|' M:servers/sdk/config.zon')
                customized_configs="${customized_configs}${customized_configs:+
}$changed_path"
                ;;
            *)
                blocking_changes="${blocking_changes}${blocking_changes:+
}$line"
                ;;
        esac
    done <<EOF
$changes
EOF
fi

if [ -n "$blocking_changes" ]; then
    printf 'Nova has local changes that cannot be migrated automatically:\n' >&2
    while IFS= read -r line; do
        printf '    %s\n' "$line" >&2
    done <<EOF
$blocking_changes
EOF
    fail 'Commit, stash, or discard those changes before updating.'
fi

upstream=$(git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) ||
    fail 'The current branch has no upstream branch configured.'
git -C "$root" fetch --prune origin || fail 'Could not fetch Nova updates.'
git -C "$root" merge-base --is-ancestor HEAD "$upstream" ||
    fail "The local branch cannot be fast-forwarded to $upstream."

temporary=''
backup=''
cleanup()
{
    [ -z "$temporary" ] || rm -rf -- "$temporary"
}
trap cleanup 0 HUP INT TERM

if [ -n "$customized_configs" ]; then
    printf 'The following customized configs can be migrated:\n'
    while IFS= read -r config; do
        printf '    %s\n' "$config"
    done <<EOF
$customized_configs
EOF
    confirm 'Merge these settings into the updated configs?' ||
        fail 'Update cancelled; the customized configs were left untouched.'

    timestamp=$(date '+%Y%m%d-%H%M%S')
    backup=$(dirname -- "$root")/Nova-config-backup-$timestamp-$$
    temporary=$(mktemp -d) || fail 'Could not create a temporary update directory.'
    mkdir -p -- "$backup" || fail "Could not create '$backup'."
    has_conflict=false

    while IFS= read -r config; do
        name=$(printf '%s' "$config" | tr '/' '-')
        current=$root/$config
        saved=$backup/$name
        base=$temporary/$name.base
        incoming=$temporary/$name.incoming
        merged=$temporary/$name.merged

        cp -- "$current" "$saved" || fail "Could not back up $config."
        cp -- "$current" "$merged" || fail "Could not prepare $config for merging."
        git -C "$root" show "HEAD:$config" >"$base" || fail "Could not read the previous version of $config."
        git -C "$root" show "$upstream:$config" >"$incoming" || fail "The updated branch no longer contains $config."
        if ! git merge-file --quiet -- "$merged" "$base" "$incoming"; then
            has_conflict=true
        fi
    done <<EOF
$customized_configs
EOF

    if "$has_conflict"; then
        printf 'Your config files were backed up to:\n    %s\n' "$backup" >&2
        fail 'The customized configs conflict with the update. Nova was not updated.'
    fi

    while IFS= read -r config; do
        git -C "$root" restore --worktree -- "$config" ||
            fail "Could not temporarily restore $config."
    done <<EOF
$customized_configs
EOF
fi

if ! git -C "$root" merge --ff-only "$upstream"; then
    if [ -n "$backup" ]; then
        while IFS= read -r config; do
            name=$(printf '%s' "$config" | tr '/' '-')
            cp -- "$backup/$name" "$root/$config" || true
        done <<EOF
$customized_configs
EOF
    fi
    fail "Nova could not be fast-forwarded to $upstream."
fi

if [ -n "$customized_configs" ]; then
    while IFS= read -r config; do
        name=$(printf '%s' "$config" | tr '/' '-')
        cp -- "$temporary/$name.merged" "$root/$config" ||
            fail "Nova was updated, but the merged $config could not be restored. Your backup is at $backup."
    done <<EOF
$customized_configs
EOF
fi

cleanup
temporary=''
trap - 0 HUP INT TERM
printf 'Nova is up to date.\n'
