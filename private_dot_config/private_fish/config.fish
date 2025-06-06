# Environment Variables
if status is-interactive
    set -gx EDITOR nvim
    set -gx PATH /opt/homebrew/bin $PATH
    set -gx fish_key_bindings fish_vi_key_bindings

    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Direnv Setup (moved inside interactive check)
    direnv hook fish | source

    # Direnv behavior configuration
    set -g direnv_fish_mode eval_on_arrow
end

# Key Bindings
set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

# Shell Integrations
atuin init fish | source # Shell history
zoxide init fish | source # Smart directory jumping

# Core Command Aliases
abbr --add -g cd z
abbr --add -g v nvim
abbr --add -g vi nvim
abbr --add -g vim nvim
abbr --add -g v. nvim .
abbr --add -g x exit
abbr --add -g g lazygit

# Task Management Aliases
abbr --add -g t task
abbr --add -g tt taskwarrior-tui

# Better Alternatives
abbr --add -g cat bat

# Safety Features
# Move files to trash instead of deleting them (requires `brew install trash`)
if type -q trash
    abbr --add -g rm trash
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
