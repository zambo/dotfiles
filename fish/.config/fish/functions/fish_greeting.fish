function fish_greeting --description "Show pending taskwarrior tasks on new shell"
    if not type -q task
        return
    end

    set -l total (task rc.verbose=nothing +PENDING count 2>/dev/null)
    if test -z "$total" -o "$total" = 0
        return
    end

    set_color --bold blue
    if test "$total" = 1
        echo "You have 1 pending task:"
    else
        echo "You have $total pending tasks:"
    end
    set_color normal

    task rc.verbose=nothing \
        rc.report.next.columns=id,description.truncated,due.relative,priority \
        rc.report.next.labels=ID,Task,Due,Pri \
        next limit:5 2>/dev/null

    if test "$total" -gt 5
        set_color --dim
        echo -n (math "$total - 5")" more - run "
        set_color --bold
        echo -n ttn
        set_color --dim
        echo " to see all"
        set_color normal
    end
end
