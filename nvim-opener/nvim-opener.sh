#!/bin/bash
BAT=/opt/homebrew/bin/bat
NVIM=/opt/homebrew/bin/nvim

open_in_ghostty() {
  local cmd="$1"
  python3 << EOF
import subprocess
cmd = """$cmd"""
script = """
tell application "Ghostty"
  activate
  set cfg to new surface configuration
  set command of cfg to "$cmd"
  new window with configuration cfg
end tell
"""
subprocess.run(["osascript", "-e", script], check=True)
EOF
}

if [ "$#" -eq 0 ]; then
  open_in_ghostty "$NVIM"
else
  FILE="$1"

  # Write a temp runner script to avoid quoting issues in AppleScript
  RUNNER=$(mktemp /tmp/nvim-opener-XXXXXX.sh)
  chmod +x "$RUNNER"
  cat > "$RUNNER" << RUNNER
#!/bin/bash
$BAT $(printf '%q' "$FILE")
printf '\n\033[1mpress e to edit, any other key to close...\033[0m '
read -r -s -n1 key
echo
if [ "\$key" = "e" ]; then
  $NVIM $(printf '%q' "$FILE")
fi
rm -f "$RUNNER"
RUNNER

  open_in_ghostty "$RUNNER"
fi
