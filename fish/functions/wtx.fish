function wtx
    set -l raw_branch $argv[1]
    set -l branch (string replace -ra '[.:/]' '-' -- $raw_branch)
    if set -q argv[2]
        tmux new-session -d -s $branch "wt switch --create $branch -x 'claude --dangerously-skip-permissions' -- '$argv[2]'"
    else
        tmux new-session -d -s $branch "wt switch --create $branch -x 'claude --dangerously-skip-permissions'"
    end
end
