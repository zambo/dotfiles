function stowify --description 'Convert directories to stow pattern: appname/.config/appname'
    if test (count $argv) -eq 0
        echo "Usage: stowify <appname...> or stowify <pattern>"
        echo "Converts directories to appname/.config/appname structure for stow"
        echo "Examples:"
        echo "  stowify nvim git"
        echo "  stowify app*"
        return 1
    end

    for appname in $argv
        if not test -d $appname
            echo "Warning: Directory '$appname' does not exist - skipping"
            continue
        end

        if test -d $appname/.config
            echo "Warning: '$appname/.config' already exists - skipping"
            continue
        end

        echo "Converting '$appname' to stow pattern..."
        
        set temp_dir (mktemp -d)
        if count $appname/* >/dev/null 2>&1
            mv $appname/* $temp_dir/ 2>/dev/null
        end
        mkdir -p $appname/.config
        if count $temp_dir/* >/dev/null 2>&1
            mv $temp_dir/* $appname/.config/$appname/ 2>/dev/null
        end
        rmdir $temp_dir

        echo "✓ Converted '$appname' to '$appname/.config/$appname'"
    end
end