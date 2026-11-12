function multicd --description "Expand .. / ... / .... into cd ../ chains"
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
