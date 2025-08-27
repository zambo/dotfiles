# Environment Variables
if status is-interactive
    set -gx EDITOR nvim
    set -gx PATH /opt/homebrew/bin $PATH
    set -gx fish_key_bindings fish_vi_key_bindings

    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Direnv Setup (moved inside interactive check)
    if type -q direnv
        direnv hook fish | source
        # Direnv behavior configuration
        set -g direnv_fish_mode eval_on_arrow
    end
end

# Shell Variables
set -x STOW_DIR ~/dotfiles

# Key Bindings
set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

# Shell Integrations
# Source atuin environment first
if test -f ~/.atuin/bin/env.fish
    source ~/.atuin/bin/env.fish
end

# Initialize shell tools (only if they exist)
if type -q atuin
    atuin init fish | source # Shell history
end
if type -q zoxide  
    zoxide init fish | source # Smart directory jumping
end

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

alias claude="/Users/zambo/.claude/local/claude"

# pnpm
set -gx PNPM_HOME "/Users/zambo/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -x ZEPHYR_SDK_INSTALL_DIR ~/zephyr-sdk-0.16.8
set -x ZEPHYR_SDK_INSTALL_DIR ~/zephyr-sdk-0.16.8
