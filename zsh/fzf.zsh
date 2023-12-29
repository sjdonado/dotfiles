export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"

export FZF_CTRL_T_OPTS="
  --min-height 30
  --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"

export FZF_CTRL_R_OPTS="
  +s +m -x -e --preview-window=hidden
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
