#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 --new <branch_name> [--setup] [--remove] [--help]"
  echo ""
  echo "Options:"
  echo "  --new <branch_name>         Specify the new branch name."
  echo "  --remove <branch_name>      Remove the worktree and kill the tmux session."
  echo "  --setup                     Run the pnpm run build command in the monorepo tmux window."
  echo "  --help                      Display this help message."
  exit 0
}

# Check if no arguments are provided or if --help flag is present
if [ "$#" -eq 0 ] || [[ " $* " == *" --help "* ]]; then
  usage
fi

# Parse arguments
branch_name=""
add_worktree=false
run_setup=false
remove_worktree=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --new)
      add_worktree=true
      branch_name=$2
      shift
      ;;
    --remove)
      remove_worktree=true
      branch_name=$2
      shift
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

if [ -z "$branch_name" ]; then
  usage
fi

# Set variables
base_path=$(git rev-parse --show-toplevel)
worktree_path="$base_path/../$branch_name"
web_path="$worktree_path/apps/web"
customer_portal_path="$worktree_path/apps/customer-portal"
api_path="$worktree_path/apps/api"
supabase_path="$worktree_path/apps/supabase"
packages_path="$worktree_path/packages"

if $remove_worktree; then
  if [ -d "$worktree_path" ]; then
    git worktree remove "$worktree_path"
  else
    echo "Worktree path does not exist: $worktree_path"
  fi

  if tmux has-session -t "$branch_name" 2>/dev/null; then
    tmux kill-session -t "$branch_name"
  else
    echo "Tmux session does not exist: $branch_name"
  fi

  exit 0
fi

if $add_worktree; then
  # Step 0: Update refs
  git fetch

  # Step 1: Create a new git worktree based on the argument sent (branch name)
  git worktree add --checkout -B "$branch_name" "$worktree_path"

  # Step 2: Create a new tmux session with the same branch name
  tmux new-session -d -s "$branch_name"

  # Step 2.1: Set environment variables for the tmux session
  tmux set-environment -t "$branch_name" NODE_OPTIONS "--max_old_space_size=6144"
  tmux set-environment -t "$branch_name" SUPABASE_WORKDIR "$worktree_path/apps"

  # Step 3: Open a window inside the folder in the new tmux session
  tmux new-window -t "$branch_name" -n 'monorepo'
  tmux kill-window -t "$branch_name:0"
  tmux send-keys -t "$branch_name:0" "cd $worktree_path" C-m

  # Step 4: Open a window for each specified path
  tmux new-window -t "$branch_name" -n 'api'
  tmux send-keys -t "$branch_name:1" "cd $api_path" C-m

  tmux new-window -t "$branch_name" -n 'web'
  tmux send-keys -t "$branch_name:2" "cd $web_path" C-m

  tmux new-window -t "$branch_name" -n 'customer-portal'
  tmux send-keys -t "$branch_name:3" "cd $customer_portal_path" C-m

  tmux new-window -t "$branch_name" -n 'supabase'
  tmux send-keys -t "$branch_name:4" "cd $supabase_path" C-m

  tmux new-window -t "$branch_name" -n 'packages'
  tmux send-keys -t "$branch_name:5" "cd $packages_path" C-m

  # Step 5: Copy .env files from the original folder to the new locations
  if [ -f "$base_path/apps/web/.env" ]; then
    cp "$base_path/apps/web/.env" "$web_path/.env"
  else
    echo "File not found: $base_path/apps/web/.env"
  fi

  if [ -f "$base_path/apps/api/.env" ]; then
    cp "$base_path/apps/api/.env" "$api_path/.env"
  else
    echo "File not found: $base_path/apps/api/.env"
  fi

  # Step 6: Run the pnpm run build command if --setup flag is provided
  if $run_setup; then
    tmux send-keys -t "$branch_name:0" "pnpm install && pnpm run build" C-m
  fi

  # Step 7: Split the pane horizontally and open nvim in the upper pane for each window
  for i in {1..4}; do
    tmux split-window -v -t "$branch_name:$i"
    tmux resize-pane -Z -t "$branch_name:$i.0"
    tmux send-keys -t "$branch_name:$i.0" "nvim ." C-m
    tmux send-keys -t "$branch_name:$i.1" "cd ${worktree_path}/apps" C-m
  done

  # Attach to the tmux session
  # tmux attach -t "$branch_name"
fi
