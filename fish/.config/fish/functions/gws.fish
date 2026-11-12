function gws --description "gws CLI, auto-injecting a fresh gcloud access token"
    # Shadows the real `gws` binary on purpose so every call gets a fresh token
    # (tokens expire hourly, so there's no safe way to cache one here).
    # Reach the unwrapped binary directly with: command gws ...
    set -l is_help 0
    if contains -- -h $argv; or contains -- --help $argv; or test "$argv[1]" = help
        set is_help 1
    end

    # Account is set via GWS_CLI_ACCOUNT in ~/.env.global; falls back to gcloud's active account.
    set -l gws_account $GWS_CLI_ACCOUNT
    if test -z "$gws_account"
        set gws_account (gcloud config get-value account 2>/dev/null)
    end

    set -lx GOOGLE_WORKSPACE_CLI_TOKEN (gcloud auth print-access-token --account="$gws_account")
    command gws $argv

    if test $is_help -eq 1
        echo >&2
        echo "NOTE:" >&2
        echo "    gws is wrapped by a fish function to auto-inject GOOGLE_WORKSPACE_CLI_TOKEN." >&2
        echo "    Run 'command gws ...' to bypass the wrapper and call the real binary." >&2
    end
end
