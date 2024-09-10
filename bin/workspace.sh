#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 --new <branch_name> [--database <database_name>] [--setup] [--remove] [--drop-database] [--help]"
  echo ""
  echo "Options:"
  echo "  --new <branch_name>         Specify the new branch name."
  echo "  --remove <branch_name>      Remove the worktree, kill the tmux session, and drop the specified database."
  echo "  --database <database_name>  Specify the database name to replace in the DATABASE_URL."
  echo "  --setup                     Run the ./cicd-setup.sh script in the monorepo tmux window."
  echo "  --drop-database             Drop the specified database."
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
run_setup=false
remove_worktree=false
drop_database=false

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
    --drop-database)
      drop_database=true
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

# Function to extract database name from DATABASE_URL
extract_db_name() {
  local url=$1
  echo "$url" | sed -n 's|.*//.*:.*@.*:\(.*\)/\([^?]*\)?.*|\2|p'
}

if $remove_worktree; then
  if $drop_database; then
    if [ -f "$api_path/.env" ]; then
      database_url=$(grep '^DATABASE_URL=' "$api_path/.env" | sed 's/^DATABASE_URL=//')
      db_name=$(extract_db_name "$database_url")

      if [ -n "$db_name" ]; then
        PGPASSWORD="$password" psql -U "$user" -h "$host" -p "$port" -d postgres -c "DROP DATABASE IF EXISTS \"$db_name\";"
      else
        echo "Database name not found in DATABASE_URL"
        exit 1
      fi
    else
      echo "File not found: $api_path/.env"
      exit 1
    fi
  fi

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
  # Step 0 update refs
  git fetch

  # Step 1: Create a new git worktree based on the argument sent (branch name)
  git worktree add --checkout -B "$branch_name" "$worktree_path"

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
  if [ -f "$base_path/Api/.env" ]; then
    cp "$base_path/Api/.env" "$api_path/.env"
  else
    echo "File not found: $base_path/Api/.env"
    exit 1
  fi

  if [ -f "$base_path/Portal/.env" ]; then
    cp "$base_path/Portal/.env" "$portal_path/.env"
  else
    echo "File not found: $base_path/Portal/.env"
    exit 1
  fi

  original_db_name=$(extract_db_name "$(grep '^DATABASE_URL=' "$api_path/.env" | sed 's/^DATABASE_URL=//')")

  # Step 7: Update `DATABASE_URL` variable in the ./Api/.env file if the database_name is provided
  if [ -n "$database_name" ]; then
    sed -i '' "s|\(DATABASE_URL=.*\)$original_db_name|\1$database_name|g" "$api_path/.env"
  fi

  # Step 8: If --setup flag is provided, run the cicd-setup.sh script
  if $run_setup; then
    tmux send-keys -t "$branch_name:0" "./cicd-setup.sh" C-m
    tmux send-keys -t "$branch_name:1" "pnpm db-duplicate $original_db_name $database_name" C-m
    tmux send-keys -t "$branch_name:1" "clear" C-m
  fi

  # Step 9: Split the pane horizontally and open nvim in the upper pane for Api and Portal windows
  tmux split-window -v -t "$branch_name:1"
  tmux resize-pane -Z -t "$branch_name:1.0"
  tmux send-keys -t "$branch_name:1.0" "nvim ." C-m
  tmux send-keys -t "$branch_name:1.1" "cd $api_path" C-m

  tmux split-window -v -t "$branch_name:2"
  tmux resize-pane -Z -t "$branch_name:2.0"
  tmux send-keys -t "$branch_name:2.0" "nvim ." C-m
  tmux send-keys -t "$branch_name:2.1" "cd $portal_path" C-m

  # Attach to the tmux session
  # tmux attach -t "$branch_name"
fi
