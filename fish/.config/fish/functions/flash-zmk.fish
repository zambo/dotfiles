function flash_nicenano
    set firmware_file "$HOME/Development/zambo/zmk-config/firmware/nice_view-eyelash_corne_left.uf2"
    set mount_point "/Volumes/NICENANO"

    echo "Debug: Checking firmware file..."
    echo "Path: $firmware_file"

    if test -f $firmware_file
        echo "✓ Firmware file exists"
        ls -la $firmware_file
    else
        echo "✗ Firmware file NOT found at $firmware_file"
        return 1
    end

    echo ""
    echo "Debug: Checking mount point..."
    echo "Path: $mount_point"

    if test -d $mount_point
        echo "✓ NICENANO is mounted"
        echo "Mount contents before copy:"
        ls -la $mount_point
    else
        echo "✗ NICENANO not mounted at $mount_point"
        echo "Available volumes:"
        ls /Volumes/
        return 1
    end

    echo ""
    echo "Debug: Attempting copy..."
    echo "Command: cp -v $firmware_file $mount_point/"

    cp -v $firmware_file $mount_point/
    set copy_status $status

    echo "Copy exit status: $copy_status"

    if test $copy_status -eq 0
        echo ""
        echo "Mount contents after copy:"
        ls -la $mount_point
        sync
        echo "Sync completed"
        return 0
    else
        echo "Copy failed with status $copy_status"
        return 1
    end
end
