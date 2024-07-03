#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 --new <branch_name> [--database <database_name>] [--setup] [--remove] [--help]"
  echo ""
  echo "Options:"
  echo "  --new <branch_name>         Specify the new branch name."
  echo "  --remove <branch_name>      Remove the worktree, kill the tmux session, and drop the specified database."
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
add_worktree=false
remove_worktree=false
run_setup=false

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
base_path=$(git rev-parse --show-toplevel)
worktree_path="$base_path/../$branch_name"
api_path="$worktree_path/Api"
portal_path="$worktree_path/Portal"

if $remove_worktree; then
  git worktree remove "$worktree_path"
  tmux kill-session -t "$branch_name"

  # Drop the database if the database_name is provided
  if [ -n "$database_name" ]; then
    database_url=$(grep '^DATABASE_URL=' "$api_path/.env" | sed 's/^DATABASE_URL=//')
    db_user=$(echo $database_url | awk -F[/:@] '{print $4}')
    db_password=$(echo $database_url | awk -F[@:/] '{print $5}')
    db_host=$(echo $database_url | awk -F[@:/] '{print $6}')
    db_name=$(echo $database_url | awk -F[/:] '{print $4}')

    PGPASSWORD="$db_password" psql -U "$db_user" -h "$db_host" -d postgres -c "DROP DATABASE IF EXISTS $database_name;"
  fi

  exit 0
fi

if $add_worktree; then
  # Step 1: Create a new git worktree based on the argument sent (branch name)
  git worktree add -B "$branch_name" "$worktree_path"

  # Step 2: Create a new tmux session with the same branch name
  tmux new-session -d -s "$branch_name"

  # Step 3: Open a window inside the folder in the new tmux session and rename the session with the name `monorepo`
  tmux rename-window -t "$branch_name:0" 'monorepo'
  tmux send-keys -t "$branch_name:0" "cd $worktree_path" C-m

  # Step 4: Open another window with the name `api` inside the ./Api folder in that workspace
  tmux new-window -t "$branch_name" -n 'api'
  tmux send-keys -t "$branch_name:1" "cd $api_path" C-m

  # Step 5: Open another window with the name `portal` inside the ./Portal folder in that workspace
  tmux new-window -t "$branch_name" -n 'portal'
  tmux send-keys -t "$branch_name:2" "cd $portal_path" C-m

  # Step 6: Copy .env variables from the original folder (development) to the ./Api and ./Portal
  cp "$base_path/Api/.env" "$api_path/.env"
  cp "$base_path/Portal/.env" "$portal_path/.env"

  # Step 7: Update `DATABASE_URL` variable in the ./Api/.env file if the database_name is provided
  if [ -n "$database_name" ]; then
    sed -i '' "s|\(DATABASE_URL=.*\)development|\1$database_name|g" "$api_path/.env"
  fi

  # Step 8: If --setup flag is provided, run the cicd-setup.sh script
  if $run_setup; then
    tmux send-keys -t "$branch_name:0" "./cicd-setup.sh" C-m
    tmux send-keys -t "$branch_name:1" "pnpm db-duplicate development $database_name" C-m
  fi

  # Step 9: Open editor
  tmux send-keys -t "$branch_name:1" "nvim ." C-m
  tmux send-keys -t "$branch_name:2" "nvim ." C-m

  # Attach to the tmux session
  # tmux attach -t "$branch_name"
fi
