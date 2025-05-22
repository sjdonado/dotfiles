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
minimize_panes=false
branch_name=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --open)
            add_worktree=true
            branch_name=$2; shift
            ;;
        --remove)
            remove_worktree=true
            if [[ $# -gt 1 && $2 != --* ]]; then
                branch_name=$2; shift
            else
                branch_name=$(git branch --show-current)
            fi
            ;;
        --close)
            close_session=true
            if [[ $# -gt 1 && $2 != --* ]]; then
                branch_name=$2; shift
            else
                branch_name=$(git branch --show-current)
            fi
            ;;
        --minimize)
            minimize_panes=true
            if [[ $# -gt 1 && $2 != --* ]]; then
                branch_name=$2; shift
            else
                branch_name=$(git branch --show-current)
            fi
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

if { $add_worktree || $remove_worktree || $close_session || $minimize_panes; } && [[ -z "${branch_name}" ]]; then
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
    protected=(_main _master main master)
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

if $minimize_panes; then
    # “.” means “current tmux session” when inside tmux, otherwise current git branch
    if [[ "$branch_name" == "." ]]; then
        if [[ -n "$TMUX" ]]; then
            session=$(tmux display-message -p '#S')
        else
            session=$(git branch --show-current)
        fi
    else
        session="$branch_name"
    fi

    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "No tmux session: $session"
        exit 1
    fi

    # list every pane in every session, but only act on panes whose session_name matches
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" | \
    grep "^${session}:" | \
    while read -r pane cmd; do
        if [[ "$cmd" == "nvim" ]]; then
            echo "Closing nvim in pane $pane"
            tmux send-keys -t "$pane" ":qa!" C-m
        else
            tmux send-keys -t "$pane" C-c
        fi
    done

    exit 0
fi

if $add_worktree; then
    # Create worktree if missing
    if [[ -d "${worktree_path}" ]]; then
        echo "Reusing existing worktree at: ${worktree_path}"
        [[ ! -e "${worktree_path}/.git" ]] && { echo "Error: ${worktree_path} is not a git worktree"; exit 1; }
    else
        git fetch
        git worktree add --checkout -B "${branch_name}" "${worktree_path}"
    fi

    # Tmux session cleanup
    if tmux has-session -t "${branch_name}" 2>/dev/null; then
        echo "Killing existing tmux session: ${branch_name}"
        tmux kill-session -t "${branch_name}"
    fi

    # Tmux session setup
    tmux new-session -d -s "${branch_name}" -n "~" -c "${worktree_path}"

    # Set workspace environment variables
    for var_name in $(printenv | grep -oE '^WORKSPACE_[^=]+' | grep -v '^WORKSPACE_INTERNAL'); do
        env_key="${var_name#WORKSPACE_}"
        env_value="${!var_name}"
        tmux set-environment -t "${branch_name}" "${env_key}" "${env_value}"
    done

    # Create windows & panes per layout
    window_index=1
    for item in "${paths[@]}"; do
        name="${item%%:*}"
        rel_path="${item#*:}"
        full_path="${worktree_path}/${rel_path}"

        if [[ -d "${full_path}" ]]; then
            tmux new-window -t "${branch_name}:${window_index}" -n "${name}" -c "${full_path}"
        else
            echo "Warning: Path not found - ${full_path}"
            tmux new-window -t "${branch_name}:${window_index}" -n "${name}" -c "${worktree_path}"
        fi

        tmux split-window -v -t "${branch_name}:${window_index}"
        tmux resize-pane -Z -t "${branch_name}:${window_index}.0"
        tmux send-keys -t "${branch_name}:${window_index}.1" "cd ${full_path}" C-m

        ((window_index++))
    done

    # Environment file handling
    for item in "${paths[@]}"; do
        rel_path="${item#*:}"
        src="${base_path}/${rel_path}/.env"
        dest="${worktree_path}/${rel_path}/.env"

        if [[ -f "${src}" ]]; then
            if [[ -f "${dest}" ]]; then
                echo "Preserving existing: ${dest}"
            else
                echo "Copying environment file: ${rel_path}/.env"
                cp "${src}" "${dest}"
            fi
        else
            echo "Warning: .env file not found for folder: ${rel_path}"
        fi
    done

    # Post-setup commands
    if $run_setup; then
        if [[ -z "${WORKSPACE_INTERNAL_SETUP_CMD}" ]]; then
            echo "Error: WORKSPACE_INTERNAL_SETUP_CMD is not set"
            exit 1
        fi
        tmux send-keys -t "${branch_name}:0" "${WORKSPACE_INTERNAL_SETUP_CMD}" C-m
    fi

    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "${branch_name}"
    else
      tmux attach-session -t "${branch_name}"
    fi
fi
