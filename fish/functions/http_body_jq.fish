# Example ~> curl -sv https://httpbin.org/json 2>&1 | http_body_jq
function http_body_jq
    set -l tmpfile (mktemp)

    # Normalize HTTP/1.1 CRLF to LF and save to tmp file
    tr -d '\r' > $tmpfile

    # If the file contains curl verbose output (starts with *)
    if grep -q '^\*' $tmpfile
        grep '^\* Connected to ' $tmpfile | sed 's/^\* Connected to /* Connected to/'
        echo ""
        echo "* Request Headers"
        grep '^>' $tmpfile | sed 's/^> //'
        echo "* Response Headers"
        grep '^<' $tmpfile | sed 's/^< //'

        # Extract JSON by finding where the actual JSON content begins
        # Look for a line starting with { that comes after headers
        set -l start_line (grep -n '^{' $tmpfile | tail -n 1 | cut -d':' -f1)
        if test -n "$start_line"
            tail -n +$start_line $tmpfile | jq -C $argv
        end
    else
        # Display headers (everything before the first blank line)
        sed -n '1,/^$/p' $tmpfile
        sed '1,/^$/d' $tmpfile | jq -C $argv
    end

    rm $tmpfile
end
