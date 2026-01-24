# Fish completion for opencode

function __fish_opencode_complete
    set -l cmd (commandline -opc)
    opencode --get-yargs-completions $cmd
end

complete -c opencode -f -a '(__fish_opencode_complete)'
