# retrieve command cheat sheets from cheat.sh
# fish completion for cht.sh

# Function to get cht.sh completions
function __fish_cht_sh_complete
    if not set -q __CHTSH_LANGS
        set -g __CHTSH_LANGS (curl -s cheat.sh/:list 2>/dev/null)
    end
    printf "%s\n" $__CHTSH_LANGS
end

# register completions for cht.sh
complete -c cht.sh -xa '(__fish_cht_sh_complete)'
