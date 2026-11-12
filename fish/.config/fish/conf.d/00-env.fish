# Load environment variables from ~/.env.global (not in the repo).
# Lives in conf.d with a 00- prefix so it runs before abbr.fish, which uses $JIRA_* at definition time.
if status is-interactive
    loadenv "$HOME/.env.global"
end
