# Shared non-interactive shell environment.
case "$(uname -s)" in
  Darwin) export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" ;;
  *) export PATH="$HOME/.local/bin:$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" ;;
esac
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
ulimit -c 0
