function learning-queue --description "Append an item to the Info Dump section of the engineering continuous-learning note"
    if test (count $argv) -eq 0
        echo "Usage: learning-queue <text to add to the learning queue>"
        return 1
    end

    # NOTE: hardcoded for now (single use case). Could grow --file/--section
    # flags later if this pattern gets reused for other notes/sections.
    set -l target_file "$NOTES_DIR/engineering-continuous-learning.md"
    set -l section_header "## Info Dump"
    set -l entry (string join " " $argv)

    if not test -f "$target_file"
        echo "Error: file not found: $target_file"
        return 1
    end

    if not grep -qF "$section_header" "$target_file"
        echo "Error: section '$section_header' not found in $target_file"
        return 1
    end

    awk -v header="$section_header" -v entry="- $entry" '
        BEGIN { in_section=0; n=0 }
        {
            if (in_section && $0 ~ /^## /) {
                while (n > 0 && buf[n] == "") { n-- }
                for (i = 1; i <= n; i++) print buf[i]
                print entry
                print ""
                in_section = 0
                n = 0
                print
                next
            }
            if (in_section) {
                buf[++n] = $0
                next
            }
            print
            if ($0 == header) { in_section = 1 }
        }
        END {
            if (in_section) {
                while (n > 0 && buf[n] == "") { n-- }
                for (i = 1; i <= n; i++) print buf[i]
                print entry
            }
        }
    ' "$target_file" > "$target_file.tmp" && mv "$target_file.tmp" "$target_file"
end
