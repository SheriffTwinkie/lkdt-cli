#!/bin/bash

REPO="kong/kong-gateway"
URL="https://hub.docker.com/v2/repositories/$REPO/tags/"
PAGE_SIZE=100
PAGE=1

echo "Fetching all tags for $REPO..."

while true; do
    RESPONSE=$(curl -s "$URL?page=$PAGE&page_size=$PAGE_SIZE")
    TAGS=$(echo "$RESPONSE" | jq -r '.results[].name')

    if [ -z "$TAGS" ]; then
        break
    fi

    echo "$TAGS"
    PAGE=$((PAGE + 1))
done


# fails at end with 
# jq: error (at <stdin>:1): Cannot iterate over null (null)

# could also stop it at 2.8+
# could also add numbers only, remove all the -distro results

