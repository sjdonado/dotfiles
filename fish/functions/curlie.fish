# Example ~> curlie -sv https://httpbin.org/json
function curlie
    if not command -sq jq
        echo "jq is not installed. Installing with Homebrew..."
        brew install jq
        if test $status -ne 0
            echo "Error installing jq. Please install it manually."
            return 1
        end
    end
    if not command -sq xq
        echo "xq is not installed. Installing xq with Homebrew..."
        brew install xq
        if test $status -ne 0
            echo "Error installing xq. Please install it manually."
            return 1
        end
    end

    set -l curl_args
    set -l processor_args
    set -l url_found 0
    set -l has_v 0
    set -l has_s 0

    for arg in $argv
        # If it starts with '-', it's a curl option
        if string match -q -- '-*' $arg; and test $url_found -eq 0
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
        # Otherwise, assume it's an argument for jq/xq processor
        else
            set -a processor_args $arg
        end
    end

    if test $has_v -eq 0
        set -a curl_args "-v"
    end

    if test $has_s -eq 0
        set -a curl_args "-s"
    end

    set -l stderr_file (mktemp)
    set -l body_file (mktemp)

    # Run curl with stdout going directly to body_file and stderr to stderr_file
    curl $curl_args > $body_file 2> $stderr_file

    # Clean up stderr file by removing carriage returns
    cat $stderr_file | tr -d '\r' > $stderr_file.clean
    mv $stderr_file.clean $stderr_file

    if ! grep -q '^\*' $stderr_file
        # Not curl verbose output, just display the body content as is
        cat $body_file
        rm $stderr_file $body_file
        return
    end

    # Display connection information
    if test $has_v -eq 1
      grep '^\*' $stderr_file | sed "s/^/"(set_color 777)"/" | sed "s/\$/"(set_color normal)"/"
    else
      grep '^\* Connected to ' $stderr_file | sed 's/^\* Connected to /* Connected to /' | sed "s/^/"(set_color 777)"/" | sed "s/\$/"(set_color normal)"/"
    end

    # Request headers
    grep '^>' $stderr_file | sed 's/^> //' | sed -E "s/(.*:)(.*)/\1"(set_color cyan)"\2"(set_color normal)"/"
    # Response headers
    grep '^<' $stderr_file | sed 's/^< //' | sed -E "s/(.*:)(.*)/\1"(set_color cyan)"\2"(set_color normal)"/"

    # Check content-type from stderr
    set -l content_type (grep -i '^< content-type:' $stderr_file | head -1)
    set -l is_json 0
    set -l is_html 0
    set -l is_xml 0

    # Process the body based on content type
    if string match -q -i '*json*' -- "$content_type"
        set is_json 1
    else if string match -q -i '*html*' -- "$content_type"
        set is_html 1
    else if string match -q -i '*xml*' -- "$content_type"
        set is_xml 1
    end

    if test $is_json -eq 1
        if test (count $processor_args) -eq 0
            cat $body_file | jq '.'
        else
            cat $body_file | jq $processor_args
        end
    else if test $is_html -eq 1 -o $is_xml -eq 1
        if test (count $processor_args) -eq 0
            cat $body_file | xq
        else
            cat $body_file | xq $processor_args
        end
    else
        # For other content types, just display the body as is
        cat $body_file
    end

    rm $stderr_file $body_file
end
