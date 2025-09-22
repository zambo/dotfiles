# filepath: functions/flash_nicenano.fish
function flash_nicenano
    set firmware_file "$HOME/Development/zambo/zmk-config/firmware/nice_view-eyelash_corne_left.uf2"
    set mount_point /Volumes/NICENANO
    set timeout 30
    set interval 1

    echo "Checking firmware file at $firmware_file"
    if not test -f $firmware_file
        echo "✗ Firmware file NOT found at $firmware_file"
        return 1
    end

    echo "Looking for NICENANO at $mount_point..."
    set elapsed 0
    while not test -d $mount_point
        if test $elapsed -ge $timeout
            echo "✗ NICENANO not detected after $timeout seconds."
            return 1
        end
        if test $elapsed -eq 0
            echo "Please reset your keyboard into bootloader mode (double-tap reset or use key combo)."
        end
        sleep $interval
        set elapsed (math $elapsed + $interval)
    end

    echo "✓ NICENANO detected. Flashing firmware..."
    cp -v $firmware_file $mount_point/
    set copy_status $status

    if test $copy_status -eq 0
        sync
        echo "✓ Firmware flashed successfully."
        return 0
    else
        echo "✗ Copy failed with status $copy_status"
        return 1
    end
end
