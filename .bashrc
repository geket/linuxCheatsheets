# Obfuscated regular user
PS1='\[\e[1;32m\]$\[\e[0m\] '

# Obfuscated root user
PS1='\[\e[1;31m\]#\[\e[0m\] '

# === Infinite / Eternal Bash History ===

# Unlimited history size
export HISTSIZE=-1
export HISTFILESIZE=-1

# Timestamp format
export HISTTIMEFORMAT="%F %T "

# Use a separate eternal history file (strongly recommended)
export HISTFILE=~/.bash_eternal_history

# Append to history file instead of overwriting
shopt -s histappend

# Ignore duplicate commands + commands starting with space
export HISTCONTROL=ignoreboth:erasedups

# Write history immediately after every command (very useful)
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
