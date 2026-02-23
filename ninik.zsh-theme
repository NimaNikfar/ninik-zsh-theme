# vim:ft=zsh ts=2 sw=2 sts=2
# source: agnoster's Theme modified by ninik

### Segments of the prompt
typeset -aHg AGNOSTER_PROMPT_SEGMENTS=(
    prompt_status
    prompt_context
    prompt_virtualenv
    prompt_dir
    prompt_git
    prompt_end
)

### Segment drawing
CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
    PRIMARY_FG=black
fi

# Characters
SEGMENT_SEPARATOR="\ue0b8"
SEGMENT_INPUT="\ue0b1"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# --- FIXED PRINT_LINE FUNCTION ---
print_line() {
  # Define a default buffer if not set
  local buffer=0
  # Using a grey color by default for the line
  local dash_color='\e[38;5;241m' 
  local reset='\e[0m'
  
  # Calculate width safely
  local width=$((COLUMNS - buffer))
  
  # Print the line efficiently using printf
  printf "$dash_color"
  printf '%.0s-' {1..$width}
  printf "$reset"
}

prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Context: user@hostname with dynamic OS icon
prompt_context() {
  local user=`whoami`
  local os_icon="" # Default icon (e.g., for unknown OS or generic)

  # Check for Arch Linux
  if [[ -f "/etc/arch-release" ]]; then
    os_icon="" # Arch Linux icon (requires Nerd Font)
  # Check for macOS
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    os_icon="" # Apple logo
  fi

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment white black " %(!.%{%F{yellow}%}.)$user $os_icon %m "
  fi
}

prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules 2>/dev/null)"
  }
  ref=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="${ref} "
    fi
    ref="$BRANCH $ref"
    prompt_segment $color $PRIMARY_FG " $ref"
  fi
}

prompt_dir() {
  # Bright blue background for the directory segment
  prompt_segment '#76C2F3' $PRIMARY_FG ' %~ '
}

prompt_status() {
  local symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    prompt_segment cyan $PRIMARY_FG " $(basename $VIRTUAL_ENV) "
  fi
}

## Main prompt logic
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  for segment in "${AGNOSTER_PROMPT_SEGMENTS[@]}"; do
    [[ -n $segment ]] && $segment
  done
  print -n "\n"
  print -n "$SEGMENT_INPUT "
}

prompt_agnoster_precmd() {
  vcs_info
  # Added a leading newline to ensure the horizontal line always starts at the beginning
  PROMPT=$'\n''$(print_line)%{%f%b%k%}$(prompt_agnoster_main)'
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  prompt_opts=(cr subst percent)
  add-zsh-hook precmd prompt_agnoster_precmd
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:git*' formats '%b'
}

# Apply setup
prompt_agnoster_setup "$@"

# --- Rest of your existing ZSH configurations (setopt, bindkey, etc.) ---
setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt ksharrays           # arrays start at 0
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# hide EOL sign ('%')
export PROMPT_EOL_MARK=""

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[C' forward-word                       # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[D' backward-word                      # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[Z' undo                               # shift + tab undo last action

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# enable syntax-highlighting
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && [ "$color_prompt" = yes ]; then
 # ksharrays breaks the plugin. This is fixed now but let's disable it in the
 # meantime.
 # https://github.com/zsh-users/zsh-syntax-highlighting/pull/689
 unsetopt ksharrays
 . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
 ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
 ZSH_HIGHLIGHT_STYLES[default]=none
 ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
 ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
 #change green to blue by ninik
 ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
 ZSH_HIGHLIGHT_STYLES[global-alias]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
 ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
 ZSH_HIGHLIGHT_STYLES[path]=underline
 ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
 ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
 ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[command-substitution]=none
 ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[process-substitution]=none
 ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
 ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
 ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
 ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
 ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
 ZSH_HIGHLIGHT_STYLES[assign]=none
 ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
 ZSH_HIGHLIGHT_STYLES[named-fd]=none
 ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
 ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
 ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
 ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
 ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
 ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
 ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
 ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
 ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout    
fi

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

