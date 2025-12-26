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
set -x STOW_DIR ~/_/dotfiles
# set -gx FUELIX_KEY (op read op://iqou5ut7nmb4rwplbb4d6duh3u/rwi4fscs2fp7kc5tmlsk6rijh4/api_key)
set -U nvm_default_version v22.20.0

# echo (op read "op://private/atuin/username")
#

# not needed when using https://github.com/berk-karaal/loadenv.fish

# Key Bindings
set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

# Shell Integrations
# Source atuin environment first
# if test -f ~/.atuin/bin/env.fish
#     source ~/.atuin/bin/env.fish
# end

# Initialize shell tools (only if they exist)
if type -q atuin
    atuin init fish | source # Shell history
end
if type -q zoxide
    zoxide init fish | source # Smart directory jumping
end

# Core Command Abbreviations
# NOTE: Using abbr instead of aliases since aliases can break some scripts that rely on exact command names
abbr --add -g cd z
abbr --add -g v nvim
abbr --add -g vi nvim
abbr --add -g vim nvim
abbr --add -g v. nvim .
abbr --add -g :q exit
abbr --add -g x exit
abbr --add -g g lazygit
abbr --add -g nd npm run dev

abbr --add -g oc opencode
abbr --add -g o "open ."

abbr --add -g nc "z nvim && nvim"
abbr --add -g fc "z ~/.config/fish && nvim config.fish"

# Yarn/NPM
abbr --add -g nd "npm run dev"
abbr --add -g ni "npm install"
abbr --add -g nr "npm run"

# Docker shortcuts
abbr --add -g dcu "docker compose up"
abbr --add -g dcd "docker compose down"
abbr --add -g dcb "docker compose build"
abbr --add -g dcl "docker compose logs"

# Task Management Aliases
abbr --add -g tt taskwarrior-tui
abbr --add -g tta task add
abbr --add -g ttl task list
abbr --add -g ttc task complete
abbr --add -g ttd task done
abbr --add -g ttu task undo
# abbr --add -g tt taskwarrior-tui

# Better Alternatives
abbr --add -g cd z # zoxide for better directory navigation
abbr --add -g cat bat # bat for enhanced file viewing
abbr --add -g find fd # fd for improved file searching
abbr --add -g grep rg # ripgrep for faster searching

# Moving Directories
abbr --add -g .. "cd .."
abbr --add -g ... "cd ../.."
abbr --add -g .... "cd ../../.."
abbr --add -g ..... "cd ../../../.."
abbr --add -g ...... "cd ../../../../.."

# Safety Features
# Move files to trash instead of deleting them (requires `brew install trash`)
if type -q trash
    abbr --add -g rm trash
end

# bun
# set --export BUN_INSTALL "$HOME/.bun"
# set --export PATH $BUN_INSTALL/bin $PATH

# alias claude="/Users/zambo/.claude/local/claude"
# function claude
#     /Users/zambo/.claude/local/claude $argv
# end

# pnpm
# set -gx PNPM_HOME /Users/zambo/Library/pnpm
# if not string match -q -- $PNPM_HOME $PATH
#     set -gx PATH "$PNPM_HOME" $PATH
# end

# pnpm end

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -x ZEPHYR_SDK_INSTALL_DIR ~/zephyr-sdk-0.16.8

# Local and private variables. E.g. API keys, secrets, etc.
# if test -f ~/.config/fish/config.local.fish
#     source ~/.config/fish/config.local.fish
# end

# Load cht.sh completions manually since fish has issues with dots in completion filenames
# source ~/.config/fish/completions/cheat_sh.fish
export PATH="$HOME/.local/bin:$PATH"

# Auto load direnv
# direnv hook fish | source
