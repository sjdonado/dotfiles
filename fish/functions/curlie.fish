# Example ~> curlie -sv https://httpbin.org/json
function curlie
    set -l curl_args
    set -l jq_args
    set -l url_found 0
    set -l has_v 0
    set -l has_s 0

    for arg in $argv
        # If it starts with '-', it's a curl option
        if string match -q -- '-*' $arg
            # Check if this argument contains v or s flags
            if string match -q -- '*v*' $arg
                set has_v 1
            end
            if string match -q -- '*s*' $arg
                set has_s 1
            end
            set -a curl_args $arg
        # If we haven't found a URL yet, assume this is the URL
        else if test $url_found -eq 0
            set -a curl_args $arg
            set url_found 1
        # Otherwise, assume it's a jq filter
        else
            set -a jq_args $arg
        end
    end

    if test $has_v -eq 0
        set -a curl_args "-v"
    end

    if test $has_s -eq 0
        set -a curl_args "-s"
    end

    # Default jq filter if none provided
    if test (count $jq_args) -eq 0
        set jq_args '.'
    end

    set -l tmpfile (mktemp)

    # Run curl with curl arguments
    curl $curl_args 2>&1 | tr -d '\r' > $tmpfile

    if ! grep -q '^\*' $tmpfile
        # Not curl verbose output, just display the file content as is
        cat $tmpfile
        return
    end

    if test $has_v -eq 1
      grep '^\*' $tmpfile | sed "s/^/"(set_color 777)"/" | sed "s/\$/"(set_color normal)"/"
    else
      grep '^\* Connected to ' $tmpfile | sed 's/^\* Connected to /* Connected to /' | sed "s/^/"(set_color 777)"/" | sed "s/\$/"(set_color normal)"/"
    end

    # Request headers
    grep '^>' $tmpfile | sed 's/^> //' | sed -E "s/(.*:)(.*)/\1"(set_color cyan)"\2"(set_color normal)"/"
    # Response headers
    grep '^<' $tmpfile | sed 's/^< //' | sed -E "s/(.*:)(.*)/\1"(set_color cyan)"\2"(set_color normal)"/"

    # Check if content-type is JSON
    set -l is_json 0
    if grep -i '^< content-type:.*json' $tmpfile > /dev/null
        set is_json 1
    end

    if test $is_json -eq 1
        # Find where the JSON body starts
        set -l start_line (grep -n '^{' $tmpfile | tail -n 1 | cut -d':' -f1)

        if test -n "$start_line"
            tail -n +$start_line $tmpfile | jq -C $jq_args
        end
    else
        # For non-JSON content, just display the body without JSON parsing
        grep -v -E '^[<>*]|^[{}] \[[0-9]+ bytes data\]' $tmpfile
    end

    rm $tmpfile
end
