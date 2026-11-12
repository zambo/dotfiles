function slugify --description "Rename files to lowercase hyphenated slugs"
    set -l dry_run 0
    set -l files

    for arg in $argv
        switch $arg
            case -n --dry-run
                set dry_run 1
            case -h --help
                echo "Usage: slugify [--dry-run] FILE..."
                echo "Rename FILEs like 'Some File Name.md' to 'some-file-name.md'."
                return 0
            case '*'
                set -a files $arg
        end
    end

    if test (count $files) -eq 0
        echo "Usage: slugify [--dry-run] FILE..." >&2
        return 1
    end

    set -l force
    if test $dry_run -eq 0
        set force -f
    end

    set -l hyphenated_files
    set -l slugged_files
    for file in $files
        set -l directory (path dirname -- $file)
        set -l name (path basename -- $file)
        set name (string replace -a -r '\s+' '-' -- $name)
        set -a hyphenated_files "$directory/$name"
        set -a slugged_files "$directory/"(string lower -- $name)
    end

    if test $dry_run -eq 1
        for index in (seq (count $files))
            echo "$files[$index] -> $slugged_files[$index]"
        end
        return 0
    end

    # rnr needs two passes: one for whitespace, one for lowercasing.
    command rnr regex -f -l 0 '\s+' '-' -- $files
    or return $status
    command rnr regex -f -t lower '(.+)' '${1}' -- $hyphenated_files
end
