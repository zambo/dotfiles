function act-local
    act --cache-server-addr (ipconfig getifaddr en0) $argv
end
