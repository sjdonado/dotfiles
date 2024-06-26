#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 --new <branch_name> [--database <database_name>] [--setup] [--help]"
  echo ""
  echo "Options:"
  echo "  --new <branch_name>         Specify the new branch name."
  echo "  --database <database_name>  Specify the database name to replace 'development' in the DATABASE_URL."
  echo "  --setup                     Run the ./cicd-setup.sh script in the monorepo tmux window."
  echo "  --help                      Display this help message."
  exit 0
}

# Check if no arguments are provided or if --help flag is present
if [ "$#" -eq 0 ] || [[ " $* " == *" --help "* ]]; then
  usage
fi

# Parse arguments
branch_name=""
database_name=""
run_setup=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --new)
      branch_name=$2
      shift
      ;;
    --database)
      database_name=$2
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
base_path=$(pwd)
worktree_path="../$branch_name"
api_path="$base_path/$worktree_path/Api"
portal_path="$base_path/$worktree_path/Portal"

# Step 1: Create a new git worktree based on the argument sent (branch name)
git worktree add -B "$branch_name" "$worktree_path"

# Step 2: Create a new tmux session with the same branch name
tmux new-session -d -s "$branch_name"

# Step 3: Open a window inside the folder in the new tmux session and rename the session with the name `monorepo`
tmux rename-window -t "$branch_name:0" 'monorepo'
tmux send-keys -t "$branch_name:0" "cd $worktree_path" C-m

# Step 4: Open another window with the name `api` inside the ./Api folder in that workspace and open nvim
tmux new-window -t "$branch_name" -n 'api'
tmux send-keys -t "$branch_name:1" "cd $api_path && nvim ." C-m

# Step 5: Open another window with the name `portal` inside the ./Portal folder in that workspace and open nvim
tmux new-window -t "$branch_name" -n 'portal'
tmux send-keys -t "$branch_name:2" "cd $portal_path && nvim ." C-m

# Step 6: Copy .env variables from the original folder (development) to the ./Api and ./Portal
cp "$base_path/Api/.env" "$api_path/.env"
cp "$base_path/Portal/.env" "$portal_path/.env"

# Step 8: Update `DATABASE_URL` variable in the ./Api/.env file if the --database flag was provided
if [ -n "$database_name" ]; then
  sed -i '' "s|\(DATABASE_URL=.*\)development|\1$database_name|g" "$api_path/.env"
fi

# Step 8: If --setup flag is provided, run the cicd-setup.sh script
if $run_setup; then
  tmux send-keys -t "$branch_name:0" "./cicd-setup.sh" C-m
fi

# Attach to the tmux session
tmux attach -t "$branch_name"
