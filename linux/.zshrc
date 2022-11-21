# ZSH setup
# =========

# Fix ls colors
# eval `dircolors ${HOME}/.dir_colors`

# Probably deprecated
HIST_STAMPS="dd.mm.yyyy"
DISABLE_UNTRACKED_FILES_DIRTY="true"


# Plugins and stuff
# -----------------

# Load zgen
source ${HOME}/.zgen/zgen.zsh

# ZSH_THEME="amuse"
SPACESHIP_TIME_SHOW=true
SPACESHIP_USER_SHOW=always

# if the init script doesn't exist
if ! zgen saved; then

  zgen oh-my-zsh

  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/gitfast
  # zgen oh-my-zsh plugins/thefuck # stuck dunno why
  zgen oh-my-zsh plugins/sudo
  zgen oh-my-zsh plugins/docker
  zgen oh-my-zsh plugins/git-flow
  zgen oh-my-zsh plugins/git-extras

  zgen load spaceship-prompt/spaceship-prompt spaceship

  zgen load mafredri/zsh-async
  zgen load sindresorhus/pure


  # Too slow
  # zgen load zsh-users/zsh-syntax-highlighting

  zgen load zsh-users/zsh-autosuggestions
  zgen load zsh-users/zsh-completions
  zgen load olets/zsh-abbr

  zgen load esc/conda-zsh-completion
  
  # generate the init script from plugins above
  zgen save
fi

# Show time on right
RPROMPT='%F{white}%*'

# Enable Ctrl+Backspace
bindkey '^H' backward-kill-word
# Enable Ctrl+Delete
bindkey '^[[3;5~' kill-word


# abbr-s
# ------

# Use abbr-s instead of some aliases
ABBRS_INSTEAD_ALIASES=true

# Add some abbr-s
if [ -s "${HOME}/.config/zsh/abbreviations" ] 
then
  # abbr-s had been already added before
else
  abbr g=git
  abbr a="sudo apt"
  abbr s=sudo
  abbr gfa='git fetch --all --prune'

  if [ "$ABBRS_INSTEAD_ALIASES" = true ] ; then
    abbr appi="sudo apt install"
    abbr appu="sudo apt update"
    abbr appupg="sudo apt upgrade"
    abbr appr="sudo apt remove"
  fi
fi


# Aliases
# -------

# General
alias cl="clear"
alias cls="clear"
alias godev="cd ~/ws/"
alias rmr="rm -r"

# colored `cat`
alias dog='pygmentize -g'
alias cat='batcat'

# colored `ls` (https://github.com/athityakumar/colorls)
alias l='colorls -lA --sd'
alias lc='colorls --sd'

# APT
if ! [ "$ABBRS_INSTEAD_ALIASES" = false ] ; then
  alias appi="sudo apt install"
  alias appu="sudo apt update"
  alias appupg="sudo apt upgrade"
  alias appr="sudo apt remove"
fi

# Git
alias gitlog="git log --graph --oneline --decorate --all"
alias git↓="git pull"
alias git↑="git push"
alias gitV="git pull"
alias git^="git push"

# GitFlow
alias gitf="git flow"
alias gitf_rs="git flow release start"
alias gitf_rf="git flow release finish"
alias gitf_fs="git flow feature start"
alias gitf_ff="git flow feature finish"

# Network limits and monitor
alias wlan100="sudo wondershaper -a wlp3s0 -d 100 -u 100"
alias wlanunlim="sudo wondershaper -c -a wlp3s0"
alias net_monitor="sudo nethogs wlp3s0"

# SSH
ssh-agent-on() {
eval "$(ssh-agent)" && ssh-add ~/.ssh/id_rsa
}

# export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/keeagent.socket

# Microphone loop
alias mic_loop_on="pactl load-module module-loopback latency_msec=1"
mic_loop_off() {
pactl unload-module $(pactl list short modules | awk '$2 =="module-loopback" { print $1 }' - )
}
