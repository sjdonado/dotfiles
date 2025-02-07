#!/bin/bash

# Read window configurations from environment variable
if [[ -z "${WORKTREE_PATHS}" ]]; then
    echo "Error: WORKTREE_PATHS environment variable is not set"
    echo "Format: 'name:relative_path,name2:relative_path2'"
    exit 1
fi

IFS=',' read -ra paths <<< "${WORKTREE_PATHS}"

usage() {
    echo "Usage: $0 --open <branch_name> [--setup] [--remove [branch_name]] [--help]"
    echo ""
    echo "Options:"
    echo "  --open <branch_name>    Open new worktree and tmux session"
    echo "  --remove [branch_name]  Remove worktree and tmux session (auto-detects branch if not specified)"
    echo "  --setup                 Run pnpm install && build after creation"
    echo "  --help                  Show this help"
    exit 0
}

# Argument parsing
add_worktree=false
run_setup=false
remove_worktree=false
branch_name=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --open)
            add_worktree=true
            branch_name=$2
            shift
            ;;
        --remove)
            remove_worktree=true
            if [[ $# -gt 1 && $2 != --* ]]; then
                branch_name=$2
                shift
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

# Validate branch name when needed
if { $add_worktree || $remove_worktree; } && [[ -z "$branch_name" ]]; then
    echo "Error: Branch name required"
    usage
fi

base_path=$(git rev-parse --show-toplevel)
worktree_path="$base_path/../$branch_name"

# Removal functionality
if $remove_worktree; then
    # Prevent deletion of protected branches
    protected_branches=("main" "master")
    if [[ " ${protected_branches[@]} " =~ " $branch_name " ]]; then
        echo "Error: Refusing to remove protected branch: $branch_name"
        exit 1
    fi

    # Get registered worktree path from git
    worktree_info=$(git worktree list | grep "\[$branch_name\]$" || true)

    if [ -n "$worktree_info" ]; then
        # Extract actual worktree path from git output
        registered_path=$(echo "$worktree_info" | awk '{print $1}')
        echo "Removing registered worktree: $registered_path"

        git worktree remove "$registered_path" || {
            echo "Error: Failed to remove worktree at $registered_path"
            exit 1
        }
    elif [ -d "$worktree_path" ]; then
        # Fallback to directory check with warning
        echo "Warning: Removing unregistered worktree directory"
        rm -rf "$worktree_path"
    else
        echo "No worktree found for branch: $branch_name"
    fi

    # Cleanup tmux session
    if tmux has-session -t "$branch_name" 2>/dev/null; then
        echo "Killing tmux session: $branch_name"
        tmux kill-session -t "$branch_name"
    else
        echo "No tmux session found: $branch_name"
    fi

    exit 0
fi

# Worktree creation
if $add_worktree; then
    # Create worktree if missing
    if [ -d "$worktree_path" ]; then
        echo "Reusing existing worktree at: $worktree_path"

        # Validate existing worktree
        if [ ! -d "$worktree_path/.git" ]; then
            echo "Error: Directory exists but is not a git worktree"
            exit 1
        fi
    else
        git fetch
        git worktree add --checkout -B "$branch_name" "$worktree_path"
    fi

    # Tmux session cleanup
    if tmux has-session -t "$branch_name" 2>/dev/null; then
        echo "Killing existing tmux session: $branch_name"
        tmux kill-session -t "$branch_name"
    fi

    # Tmux session setup
    tmux new-session -d -s "$branch_name" -n "monorepo" -c "$worktree_path"
    tmux set-environment -t "$branch_name" NODE_OPTIONS "--max_old_space_size=6144"
    tmux set-environment -t "$branch_name" SUPABASE_WORKDIR "$worktree_path/apps"

    # Window creation loop
    window_index=1
    for item in "${paths[@]}"; do
        name="${item%%:*}"
        rel_path="${item#*:}"
        full_path="$worktree_path/$rel_path"

        # Create window and verify path
        if [ -d "$full_path" ]; then
            tmux new-window -t "$branch_name:$window_index" -n "$name" -c "$full_path"
        else
            echo "Warning: Path not found - $full_path"
            tmux new-window -t "$branch_name:$window_index" -n "$name" -c "$worktree_path"
        fi

        # Pane management
        tmux split-window -v -t "$branch_name:$window_index"
        tmux resize-pane -Z -t "$branch_name:$window_index.0"
        # tmux send-keys -t "$branch_name:$window_index.0" "nvim ." C-m
        tmux send-keys -t "$branch_name:$window_index.1" "cd $worktree_path" C-m

        ((window_index++))
    done

    # Environment file handling
    env_files=("apps/api/.env" "apps/web/.env" "apps/customer-portal/.env")
    for env_file in "${env_files[@]}"; do
        src="$base_path/$env_file"
        dest="$worktree_path/$env_file"

        if [ -f "$src" ]; then
            if [ -f "$dest" ]; then
                echo "Preserving existing: $dest"
            else
                echo "Copying environment file: $env_file"
                cp "$src" "$dest"
            fi
        fi
    done

    # Post-setup commands
    if $run_setup; then
        tmux send-keys -t "$branch_name:0" "pnpm install && pnpm run build" C-m
    fi
fi
