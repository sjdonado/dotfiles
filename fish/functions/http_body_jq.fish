function http_body_jq
    set -l tmpfile (mktemp)
    cat > $tmpfile

    # Display headers first
    sed -n '1,/^$/p' $tmpfile
    # Process body with jq
    sed '1,/^$/d' $tmpfile | jq $argv

    rm $tmpfile
end
