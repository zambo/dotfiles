# Dynamic completions for gws (Google Workspace CLI).
#
# gws builds its command tree at runtime from Google's Discovery Service
# (service -> resource -> [sub-resource] -> method), so there's no static
# command list to complete against. Instead, this shells out to `gws --help`
# at each level and scrapes the resulting service/command/flag list.
#
# Always calls `command gws` (the real binary), never the `gws` fish function
# defined in functions/gws.fish, so tab-completion doesn't mint a fresh
# gcloud access token on every keystroke.
#
# First completion for a given service can take ~2s (gws's own 24h Discovery
# cache is cold); subsequent completions for that service are fast (~20ms).

function __gws_complete_tokens
    # All non-flag tokens on the command line so far, excluding `gws` itself
    # and the token currently being typed (handled separately by fish).
    set -l tokens (commandline -opc)
    set -e tokens[1]
    set -l result
    for t in $tokens
        if not string match -q -- '-*' $t
            set result $result $t
        end
    end
    string join ' ' -- $result
end

function __gws_help_output
    set -l tokens (string split ' ' -- (__gws_complete_tokens))
    if test -z "$tokens[1]"
        set tokens
    end
    command gws $tokens --help 2>/dev/null
end

function __gws_complete_commands
    # Works for both the top-level `SERVICES:` block and the deeper,
    # clap-generated `Commands:` blocks — same two-column layout either way.
    __gws_help_output | awk '
        /^(SERVICES|Commands):/ { f=1; next }
        f && /^$/ { f=0 }
        f {
            line=$0
            sub(/^ +/, "", line)
            n = split(line, a, / {2,}/)
            if (a[1] != "" && a[1] != "help") {
                print a[1] "\t" a[2]
            }
        }
    '
end

function __gws_complete_flags
    __gws_help_output | awk '
        /^Options:/ { f=1; next }
        f && /^$/ { f=0 }
        f {
            line=$0
            sub(/^ +/, "", line)
            n = split(line, a, / {2,}/)
            flagpart=a[1]
            desc=a[2]
            m = split(flagpart, toks, /, /)
            for (i=1;i<=m;i++) {
                tok=toks[i]
                sub(/ <.*>$/, "", tok)
                gsub(/^ +| +$/, "", tok)
                if (tok != "-h" && tok != "--help") {
                    print tok "\t" desc
                }
            }
        }
    '
end

# Subcommands/services/resources/methods (non-flag completions)
complete -c gws -f -n 'not string match -q -- "-*" (commandline -ct)' -a '(__gws_complete_commands)'

# Flags, once the current word starts with a dash
complete -c gws -f -n 'string match -q -- "-*" (commandline -ct)' -a '(__gws_complete_flags)'
