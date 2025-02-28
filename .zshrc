# Set up the prompt

autoload -Uz promptinit
promptinit
#prompt suse

# Set color variables
autoload -U colors && colors
BLACK_FG="%F{black}"      # Black foreground
PALE_YELLOW_BG="%K{229}"  # Pale yellow background (229 in 256-color palette)
RESET_FG="%f"             # Reset foreground
RESET_BG="%k"             # Reset background

# Configure the prompt
PROMPT='${PALE_YELLOW_BG}${BLACK_FG}%n@%m: ${RESET_FG}${RESET_BG} %~/ > '

# Optional: Enable prompt substitution
setopt PROMPT_SUBST

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -v #<-- ACTUALLY using vi instead
#bindkey -e

# Set history options
#####################
HISTSIZE=1000
SAVEHIST=5000
HISTFILE=~/.zsh_history
HIST_STAMPS='%Y-%m-%d %T '
alias history="history -i"

# Additional recommended Zsh history settings
setopt histignorealldups sharehistory
setopt EXTENDED_HISTORY     # Save timestamps in history
setopt SHARE_HISTORY        # Share history across multiple sessions
setopt HIST_IGNORE_DUPS     # Ignore duplicate commands
setopt HIST_IGNORE_SPACE    # Ignore commands that start with a space
setopt HIST_VERIFY          # Show command before executing when using history expansion
setopt APPEND_HISTORY       # Append to the history file instead of overwriting it
setopt INC_APPEND_HISTORY   # Immediately add commands to history, instead of waiting for shell exit

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
autoload -Uz zsh/terminfo
zle -N adjustwinsize
adjustwinsize() { eval "$(resize)" }
TRAPWINCH() { adjustwinsize }

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Alias definitions
###################

[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# CUSTOM FUNCTIONS HERE
#######################

# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS
clean_old_snaps() {
    set -eu
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done
}

# Function to check disk space and alert if free space is below 10%
check_disk_space() {
    # Get disk usage details, filtering out filesystems like tmpfs and others typically not monitored
    df -h --exclude-type=tmpfs \
    --exclude-type=devtmpfs \
    --exclude-type=fuse.snapfuse \
    --exclude-type=iso9660 | awk 'NR>1 {if ($5+0 >= 90) print $0}'
}

check_disk_space_alert() {
    local low_space
    low_space=$(check_disk_space)

    if [[ -n "$low_space" ]]; then
        echo -e "\e[33;1mWARNING: Low disk space detected on the following filesystems:\e[0m"
        echo "$low_space"
    fi
}

check_and_set_manpager() {
    if command -v nvim &>/dev/null; then
        export MANPAGER='nvim +Man!'
        echo -e "\e[36mnvim detected. MANPAGER set to use nvim.\e[0m"
    else
        echo -e "\e[36mnvim is not installed. MANPAGER not set.\e[0m"
    fi
}

# Add this to your ~/.zshrc file

ssh-agent-start() {
    # Check if ssh-agent is already running
    if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        echo "Using existing ssh-agent (PID: $SSH_AGENT_PID)"
        return 0
    fi

    # Check for ssh-agent socket in default location
    if [ -f ~/.ssh/ssh-agent-env ]; then
        . ~/.ssh/ssh-agent-env > /dev/null
        # Verify if the agent is still running
        if ps -p $SSH_AGENT_PID > /dev/null 2>&1; then
            echo "Connected to existing ssh-agent (PID: $SSH_AGENT_PID)"
            export SSH_AUTH_SOCK SSH_AGENT_PID
            return 0
        else
            # Clean up stale env file
            rm -f ~/.ssh/ssh-agent-env
        fi
    fi

    # Start new ssh-agent if no existing one found
    echo "Starting new ssh-agent..."
    ssh-agent > ~/.ssh/ssh-agent-env
    . ~/.ssh/ssh-agent-env > /dev/null
    echo "New ssh-agent started (PID: $SSH_AGENT_PID)"
    
    # Add your default SSH key(s) - uncomment and modify as needed
    # ssh-add ~/.ssh/id_rsa
    
    export SSH_AUTH_SOCK SSH_AGENT_PID
    return 0
}

# Call the custom functions
ssh-agent-start
check_and_set_manpager
check_disk_space_alert

# Export useful variables
export PATH="$HOME/.cargo/bin:$PATH"
