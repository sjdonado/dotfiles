#!/bin/bash

# Read internal configuration
if [[ -z "${WORKSPACE_INTERNAL_LAYOUT}" ]]; then
    echo "Error: WORKSPACE_INTERNAL_LAYOUT environment variable is not set"
    echo "Format: 'name:relative_path,name2:relative_path2'"
    exit 1
fi
IFS=',' read -ra paths <<< "${WORKSPACE_INTERNAL_LAYOUT}"

usage() {
    echo "Usage: $0 --open <branch_name> [--setup] [--remove [branch_name]] [--close [branch_name]] [--minimize [branch_name]] [--help]"
    echo ""
    echo "Options:"
    echo "  --open <branch_name>      Create worktree and open tmux session"
    echo "  --remove [branch_name]    Remove worktree (auto-detects if omitted)"
    echo "  --close [branch_name]     Kill tmux session (auto-detects if omitted)"
    echo "  --minimize [branch_name]  Close all nvim panes in tmux session"
    echo "  --setup                   Run \$WORKSPACE_INTERNAL_SETUP_CMD after open"
    echo "  --help                    Show this help"
    exit 0
}

add_worktree=false
run_setup=false
remove_worktree=false
close_session=false
minimize_nvim=false
branch_name=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --open)
            add_worktree=true
            branch_name=$2; shift
            ;;
        --remove)
            remove_worktree=true
            if [[ $# -gt 1 && $2 != --* ]]; then branch_name=$2; shift
            else branch_name=$(git branch --show-current); fi
            ;;
        --close)
            close_session=true
            if [[ $# -gt 1 && $2 != --* ]]; then branch_name=$2; shift
            else branch_name=$(git branch --show-current); fi
            ;;
        --minimize)
            minimize_nvim=true
            if [[ $# -gt 1 && $2 != --* ]]; then branch_name=$2; shift
            else branch_name=$(git branch --show-current); fi
            ;;
        --setup)
            run_setup=true
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

if { $add_worktree || $remove_worktree || $close_session || $minimize_nvim; } && [[ -z "${branch_name}" ]]; then
    echo "Error: branch name required"
    usage
fi

base_path=$(git rev-parse --show-toplevel)
worktree_path="$base_path/../${branch_name}"

if $close_session; then
    if tmux has-session -t "${branch_name}" 2>/dev/null; then
        echo "Killing tmux session: ${branch_name}"
        tmux kill-session -t "${branch_name}"
    else
        echo "No tmux session found: ${branch_name}"
    fi
    exit 0
fi

if $remove_worktree; then
    protected=(main master)
    for p in "${protected[@]}"; do
        [[ "${branch_name}" == "${p}" ]] && {
            echo "Refusing to remove protected branch: ${p}"
            exit 1
        }
    done

    workdir="$base_path/../${branch_name}"
    [[ ! -d "$workdir" ]] && { echo "Cannot resolve worktree for ${branch_name}"; exit 1; }
    abs=$(command -v realpath &>/dev/null && realpath "$workdir" || cd "$workdir" && pwd -P)

    reg=$(git worktree list --porcelain | awk '$1=="worktree"{print $2}')
    if echo "$reg" | grep -Fxq "$abs"; then
        echo "Removing worktree: $abs"
        git worktree remove --force "$abs" || { echo "Failed removing worktree $abs"; exit 1; }
    else
        echo "No registered worktree at $abs"; exit 1
    fi

    # kill stray processes
    if command -v lsof &>/dev/null; then
        pids=$(lsof +D "$abs" -t 2>/dev/null)
    else
        pids=$(ps -eo pid,cmd | awk -v p="$abs" '$0~p{print $1}')
    fi
    [[ -n "$pids" ]] && echo "$pids" | xargs -r kill

    exit 0
fi

if $minimize_nvim; then
    session="$branch_name"
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "No tmux session: $session"
        exit 1
    fi
    panes=$(tmux list-panes -t "$session" -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" \
            | awk '/nvim$/ {print $1}')
    if [[ -z "$panes" ]]; then
        echo "No nvim panes in session: $session"
    else
        for p in $panes; do
            echo "Closing nvim in pane $p"
            tmux send-keys -t "$p" ":qa!" C-m
        done
    fi
    exit 0
fi

if $add_worktree; then
    if [[ -d "$worktree_path" ]]; then
        echo "Reusing worktree: $worktree_path"
        [[ ! -d "$worktree_path/.git" ]] && { echo "Not a git worktree: $worktree_path"; exit 1; }
    else
        git fetch
        git worktree add --checkout -B "$branch_name" "$worktree_path"
    fi

    # copy .env files
    for item in "${paths[@]}"; do
        rel=${item#*:}
        src="$base_path/$rel/.env"
        dst="$worktree_path/$rel/.env"
        if [[ -f "$src" && ! -f "$dst" ]]; then
            echo "Copying $rel/.env"
            cp "$src" "$dst"
        fi
    done

    echo "Worktree ready at: $worktree_path"
    cd "$worktree_path" || exit 1

    # if inside tmux already, just attach
    if [[ -n "$TMUX" ]]; then
        tmux attach-session -t "$branch_name"
        exit 0
    fi

    # always use tmux in current terminal
    tmux new-session -A -s "$branch_name" -c "$worktree_path"

    if $run_setup; then
        [[ -z "${WORKSPACE_INTERNAL_SETUP_CMD}" ]] && { echo "Error: WORKSPACE_INTERNAL_SETUP_CMD not set"; exit 1; }
        echo "Running setup: ${WORKSPACE_INTERNAL_SETUP_CMD}"
        eval "${WORKSPACE_INTERNAL_SETUP_CMD}"
    fi
fii
