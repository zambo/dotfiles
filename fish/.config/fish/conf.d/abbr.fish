# Abbreviations
# NOTE: Using abbr instead of aliases since aliases can break scripts that rely on exact command names

# Navigation
abbr --add -g cd z # zoxide for better directory navigation
abbr --add -g dotdot --regex '^\.\.+$' --function multicd # @see ../functions/multicd.fish for function definition

# Better Alternatives
abbr --add -g cat bat # bat for enhanced file viewing
abbr --add -g find fd # fd for improved file searching
abbr --add -g grep rg # ripgrep for faster searching

# Editor
abbr --add -g v nvim
abbr --add -g vi nvim
abbr --add -g vim nvim
abbr --add -g v. nvim . # opens nvim in current dir

# Jump directly to config files
abbr --add -g :aero "nvim ~/.config/aerospace/aerospace.toml"
abbr --add -g :fish "nvim ~/.config/fish/config.fish"
abbr --add -g :env "nvim ~/.env.global"
abbr --add -g :cc "nvim ~/.claude/settings.json"
abbr --add -g :cl "nvim ~/.claude/settings.local.json"
abbr --add -g :git "nvim ~/.config/git/config"
abbr --add -g :vk "nvim ~/.config/nvim/lua/config/keymaps.lua"
abbr --add -g :vc "nvim ~/.config/nvim/lua/config/options.lua"
abbr --add -g :zk "nvim ~/.config/zk/config.toml"

# Shell
abbr --add -g :q exit
abbr --add -g o "open ." # opens current dir in Finder

# SSH
abbr --add -g ssh "ghostty +ssh --"

# Dev Tools TUIs
abbr --add -g g lazygit
abbr --add -g d lazydocker
abbr --add -g b btui # bluetooth TUI
abbr --add -g p posting # HTTP client TUI
abbr --add -g bt bat

# OpenCode
abbr --add -g oc opencode
abbr --add -g occ --set-cursor "opencode run \"%\"" # needs prompt text

# Claude
abbr --add -g c claude
abbr --add -g cr "claude --resume"

# Gcloud
abbr --add -g gcp --set-cursor "gcloud config set project \"%\"" # needs project id
abbr --add -g gca --set-cursor "gcloud config set account \"%\"" # needs account email

# Yarn/NPM
abbr --add -g nd "npm run dev"
abbr --add -g ni "npm install"
abbr --add -g nr "npm run" # needs script name: nr build

# Docker
abbr --add -g dcu "docker compose up"
abbr --add -g dcd "docker compose down"
abbr --add -g dcb "docker compose build"
abbr --add -g dcl "docker compose logs"

# Task Management (taskwarrior)
abbr --add -g tt taskwarrior-tui # no args: opens the TUI
abbr --add -g tta task add # needs description: tta Buy milk
abbr --add -g ttl task list # no args: lists pending tasks
abbr --add -g ttd task done # needs task ID: ttd 3
abbr --add -g ttdel task delete # needs task ID: ttdel 3
abbr --add -g ttm task modify # needs task ID + mods: ttm 3 priority:H due:tomorrow
abbr --add -g tts task start # needs task ID: tts 3
abbr --add -g ttx task stop # needs task ID: ttx 3
abbr --add -g ttu task undo # no args: reverts last change
abbr --add -g ttn task next # no args: shows most urgent tasks
abbr --add -g tti task info # needs task ID: tti 3
abbr --add -g tsync task sync # no args: sync tasks with S3

# Quick Notes
abbr --add -g n --set-cursor "quicknote \"%\" \"#inbox\"" # needs note title; creates via zk, tagged #inbox
abbr --add -g ne 'cd $NOTES_DIR; and zk edit --interactive' # no args: fzf search-or-create (Ctrl-E to create from query)

# Learning Queue
abbr --add -g lq --set-cursor "learning-queue \"%\"" # needs text; appends to Info Dump section of engineering-continuous-learning.md

# Safety Features
# Move files to trash instead of deleting them (requires `brew install trash`)
if type -q trash
    abbr --add -g rm trash
end
abbr --add -g rmv "rm -rf" # explicit opt-in for permanent delete

# Jira / acli Shortcuts ($JIRA_PROJECT and $JIRA_ASSIGNEE come from ~/.env.global)

abbr --add -g jit --set-cursor "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Task\" --assignee \"$JIRA_ASSIGNEE\" --summary \"%\"" # needs summary
abbr --add -g jib --set-cursor "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Bug\" --assignee \"$JIRA_ASSIGNEE\" --summary \"%\"" # needs summary
abbr --add -g jis --set-cursor "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Story\" --assignee \"$JIRA_ASSIGNEE\" --summary \"%\"" # needs summary

# Create with editor (nvim)
abbr --add -g jite "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Task\" --assignee \"$JIRA_ASSIGNEE\" --editor" # no args: opens nvim to write it
abbr --add -g jibe "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Bug\" --assignee \"$JIRA_ASSIGNEE\" --editor" # no args: opens nvim to write it
abbr --add -g jise "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Story\" --assignee \"$JIRA_ASSIGNEE\" --editor" # no args: opens nvim to write it

# Assign an existing issue to yourself
abbr --add -g jiass --set-cursor "acli jira workitem update --issue \"%\" --assignee \"$JIRA_ASSIGNEE\"" # needs issue key: jiass PROJ-123

# List issues
abbr --add -g jimy "acli jira workitem search --jql \"project = $JIRA_PROJECT AND assignee = '$JIRA_ASSIGNEE' AND statusCategory != Done\"" # no args: my open issues
abbr --add -g jisp "acli jira workitem search --jql \"project = $JIRA_PROJECT AND sprint in openSprints() AND statusCategory != Done\"" # no args: open sprint issues
abbr --add -g jims "acli jira workitem search --jql \"project = $JIRA_PROJECT AND assignee = '$JIRA_ASSIGNEE' AND sprint in openSprints() AND statusCategory != Done\"" # no args: my open sprint issues

# Create with parent (subtask)
abbr --add -g jitp --set-cursor "acli jira workitem create --project \"$JIRA_PROJECT\" --type \"Task\" --assignee \"$JIRA_ASSIGNEE\" --parent \"%\" --summary \"\"" # needs parent issue key
