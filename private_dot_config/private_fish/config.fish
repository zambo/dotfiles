function fish
    source ~/.config/fish/config.fish
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_config theme choose tokyonight_moon
    atuin init fish | source
end

# Enable vim mode
# set -g fish_key_bindings fish_vi_key_bindings

# Abbreviations
# abbr >~/.config/fish/user/abbr.fish

# Aliases
alias v nvim
alias vi nvim
alias vim nvim

alias t task
alias tt taskwarrior-tui

alias x exit

alias cd z

alias g lazygit

# Replace original tools
alias cat bat
# alias _ ~/Development

# direnv fish config https://direnv.net/docs/hook.html#fish
direnv hook fish | source

# trigger direnv at prompt, and on every arrow-based directory change (default)
set -g direnv_fish_mode eval_on_arrow
#
# trigger direnv at prompt, and only after arrow-based directory changes before executing command
# set -g direnv_fish_mode eval_after_arrow
#
# trigger direnv at prompt only, this is similar functionality to the original behavior
# set -g direnv_fish_mode disable_arrow
#
#
zoxide init fish | source
