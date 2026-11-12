# The following lines were added by Docker Desktop to add commands to your PATH.
# export PATH="$PATH:$HOME/.docker/bin"
# End of Docker Desktop section.
set -x DOCKER_HOST unix://$HOME/.config/colima/default/docker.sock
set -x DOCKER_CONFIG $HOME/.docker-act

# Environment Variables
if status is-interactive
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx PAGER delta

    set -gx fish_key_bindings fish_vi_key_bindings

    # https://github.com/eza-community/eza?tab=readme-ov-file
    set -gx EZA_STANDARD_OPTIONS --group-directories-first --icons --git --long --header --color=auto --hyperlink --smart-group --git-repos --no-user --modified --time-style=long-iso

    # Cached `brew shellenv fish` output (regenerate with: brew shellenv fish > ~/.cache/fish/brew_shellenv.fish)
    # Avoids spawning brew as a subprocess on every shell startup.
    # NOTE: this cache goes stale if brew itself is reinstalled/upgraded/moved. Regenerate it then.
    source ~/.cache/fish/brew_shellenv.fish


    # Initialize shell tools (only if they exist)
    if type -q atuin
        atuin init fish | source # Shell history
    end

    if type -q zoxide
        zoxide init fish | source # Smart directory jumping
    end
end

set -gx NOTES_DIR ~/_/notes

# Function to create a new note via zk (handles frontmatter/YAML escaping safely)
function quicknote --description "Create a new note with zk"
    set -l title ""
    set -l tags ""

    # Parse arguments: leading #tag words become tags, everything else is the title
    for arg in $argv
        if string match -q "#*" $arg
            if test -n "$tags"
                set tags "$tags $arg"
            else
                set tags "$arg"
            end
        else if test -n "$title"
            set title "$title $arg"
        else
            set title "$arg"
        end
    end

    # Default to timestamp-based title if none provided
    if test -z "$title"
        set title (date +"%Y-%m-%d %H:%M")
    end

    if test -n "$tags"
        zk new --title "$title" --extra "tags=$tags" --working-dir $NOTES_DIR
    else
        zk new --title "$title" --working-dir $NOTES_DIR
    end
end

# Shell Variables
set -x STOW_DIR ~/_/dotfiles

# Key Bindings
set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

# NVIM_APPNAME variants (aliases, not abbrs, since these set env vars inline)
alias nvc='NVIM_APPNAME=nvim-chad nvim'
alias nvs='NVIM_APPNAME=nvim-scratch nvim'
alias nve='NVIM_APPNAME=nvim-edge nvim'

# Abbreviations live in conf.d/abbr.fish (auto-loaded by fish)

# pnpm
set -gx PNPM_HOME $HOME/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -x ZEPHYR_SDK_INSTALL_DIR ~/zephyr-sdk-0.16.8

export PATH="$HOME/.local/bin:$PATH"

# gh token for npm
set -gx NPM_TOKEN (gh auth token)

rbenv init - fish | source

# Starship
set -gx STARSHIP_CONFIG "$HOME/.config/starship/config.toml"
starship init fish | source

set -gx JAVA_HOME /opt/homebrew/opt/openjdk@17
set -gx CPPFLAGS "-I/opt/homebrew/opt/openjdk@17/include"
set -gx ANDROID_HOME $HOME/Library/Android/sdk

# OMP
set -gx PI_CONFIG_DIR ".config/omp"
