#!/bin/bash

# Read internal configuration
if [[ -z "${WORKSPACE_INTERNAL_LAYOUT}" ]]; then
    echo "Error: WORKSPACE_INTERNAL_LAYOUT environment variable is not set"
    echo "Format: 'name:relative_path,name2:relative_path2'"
    exit 1
fi

IFS=',' read -ra paths <<< "${WORKSPACE_INTERNAL_LAYOUT}"

usage() {
    echo "Usage: $0 --open <branch_name> [--setup] [--remove [branch_name]] [--help]"
    echo ""
    echo "Options:"
    echo "  --open <branch_name>    Open new worktree"
    echo "  --remove [branch_name]  Remove worktree (auto-detects branch if not specified)"
    echo "  --setup                 Run custom setup command defined in WORKSPACE_INTERNAL_SETUP_CMD"
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
if { $add_worktree || $remove_worktree; } && [[ -z "${branch_name}" ]]; then
    echo "Error: Branch name required"
    usage
fi

base_path=$(git rev-parse --show-toplevel)
worktree_path="$base_path/../${branch_name}"

if $remove_worktree; then
    protected_branches=(main master)
    for p in "${protected_branches[@]}"; do
        [[ "${branch_name}" == "${p}" ]] && {
            echo "Error: refusing to remove protected branch: ${branch_name}"
            exit 1
        }
    done

    # Determine the on-disk worktree path, then canonicalize (so ../ is removed)
    if [[ "${branch_name}" == "." ]]; then
        workdir="$PWD"
        branch_name=$(basename "${workdir}")
    else
        workdir="$base_path/../${branch_name}"
    fi
    if [[ ! -d "${workdir}" ]]; then
        echo "Error: cannot resolve worktree path for branch: ${branch_name}"
        exit 1
    fi
    if command -v realpath >/dev/null 2>&1; then
        abs_path=$(realpath "${workdir}")
    else
        abs_path=$(cd "${workdir}" && pwd -P)
    fi

    # Gather registered worktree paths
    reg_paths=$(git worktree list --porcelain | awk '$1=="worktree"{print $2}')

    if echo "${reg_paths}" | grep -Fxq "${abs_path}"; then
        echo "Removing registered worktree: ${abs_path}"
        git worktree remove --force "${abs_path}" || {
            echo "Error: failed to remove registered worktree: ${abs_path}"
            exit 1
        }
    else
        echo "No registered worktree found at: ${abs_path}"
        exit 1
    fi

    # Kill any processes running under this worktree
    echo "Scanning for processes under ${abs_path} to kill..."
    if command -v lsof >/dev/null 2>&1; then
      pids=$(lsof +D "${abs_path}" -t 2>/dev/null)
    else
      # fallback: match in command line
      pids=$(ps -eo pid,cmd | awk -v path="${abs_path}" '$0 ~ path {print $1}')
    fi
    if [[ -n "${pids}" ]]; then
      echo "Killing processes: ${pids}"
      echo "${pids}" | xargs -r kill
    fi

    exit 0
fi

if $add_worktree; then
    # Create worktree if missing
    if [ -d "${worktree_path}" ]; then
        echo "Reusing existing worktree at: ${worktree_path}"

        # Validate existing worktree
        if [ ! -d "${worktree_path}/.git" ]; then
            echo "Error: Directory exists but is not a git worktree"
            exit 1
        fi
    else
        git fetch
        git worktree add --checkout -B "${branch_name}" "${worktree_path}"
    fi

    # Environment file handling
    for item in "${paths[@]}"; do
        rel_path="${item#*:}"
        src="${base_path}/${rel_path}/.env"
        dest="${worktree_path}/${rel_path}/.env"

        if [ -f "${src}" ]; then
            if [ -f "${dest}" ]; then
                echo "Preserving existing: ${dest}"
            else
                echo "Copying environment file: ${rel_path}/.env"
                cp "${src}" "${dest}"
            fi
        else
            echo "Warning: .env file not found for folder: ${rel_path}"
        fi
    done

    # Provide helpful info
    echo "Worktree ready at: ${worktree_path}"
    echo "To open in Zed, run: zed ${worktree_path}"

    # Change directory to the worktree in the current shell
    cd "${worktree_path}"

    # Set up Ghostty layout using AppleScript for macOS
    if [[ -n "$GHOSTTY_RESOURCES_DIR" && "$(uname)" == "Darwin" ]]; then
        echo "Setting up Ghostty layout using AppleScript..."

        # Generate AppleScript to create the desired layout
        osascript -e "
        tell application \"Ghostty\"
            activate
            delay 0.5

            # Create a new tab
            tell application \"System Events\"
                keystroke \"t\" using {command down}
                delay 0.5
            end tell

            # Send the cd command to the new tab
            tell application \"System Events\" to keystroke \"cd ${worktree_path}\"
            tell application \"System Events\" to keystroke return
            delay 0.3

            # Create first vertical split (Cmd+D)
            tell application \"System Events\"
                keystroke \"d\" using {command down}
                delay 0.3
            end tell

            # Go back to left pane (Option+Cmd+Left)
            tell application \"System Events\"
                key code 123 using {option down, command down}
                delay 0.3
            end tell

            # Create horizontal split in left pane (Cmd+Shift+D)
            tell application \"System Events\"
                keystroke \"d\" using {command down, shift down}
                delay 0.3
            end tell

            # Go to right pane (Option+Cmd+Right)
            tell application \"System Events\"
                key code 124 using {option down, command down}
                delay 0.3
            end tell

            # Create horizontal split in right pane (Cmd+Shift+D)
            tell application \"System Events\"
                keystroke \"d\" using {command down, shift down}
                delay 0.3
            end tell

            # Go back to top-left pane to start working
            tell application \"System Events\"
                key code 123 using {option down, command down}
                delay 0.2
                key code 126 using {option down, command down}
            end tell
        end tell" 2>/dev/null || {
            echo "AppleScript automation failed."
            echo "To set up panes in Ghostty manually:"
            echo "1. Press Cmd+T to create a new tab and cd ${worktree_path}"
            echo "2. Press Cmd+D to split vertically"
            echo
        }
    else
        echo "To set up panes in Ghostty manually:"
        echo "1. Press Cmd+T to create a new tab and cd ${worktree_path}"
        echo "2. Press Cmd+D to split vertically"
        echo
    fi

    if $run_setup; then
        echo "Running setup command: ${WORKSPACE_INTERNAL_SETUP_CMD}"
        eval "${WORKSPACE_INTERNAL_SETUP_CMD}"
    fi
fi
