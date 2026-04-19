function fzf_git_repos --description "Fuzzy find git repos and open in new Ghostty tab"
    set -l base $HOME/Developer
    test -d $base; or set base $HOME

    set -l repo (fd -H -t d -t f --prune --max-depth 6 '^\.git$' $base 2>/dev/null | sed 's|/\.git/*$||' | fzf --height 40% --reverse --prompt "git repo> ")

    if test -z "$repo"
        commandline -f repaint
        return
    end

    printf 'tell application "Ghostty"
set w to front window
set cfg to new surface configuration
set initial working directory of cfg to "%s"
set newTab to new tab in w with configuration cfg
end tell' "$repo" | osascript

    commandline -f repaint
end
