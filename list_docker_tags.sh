#!/bin/bash

REPO="kong/kong-gateway"
URL="https://hub.docker.com/v2/repositories/$REPO/tags/"
PAGE_SIZE=100
PAGE=1
FILTER=""
LATEST_N=0

usage() {
    echo "Usage: $0 [-f filter] [-n latest_n]"
    echo "  -f filter      Only show tags matching the given filter (e.g., '3.5')"
    echo "  -n latest_n    Show only the latest N tags"
    exit 1
}

while getopts ":f:n:" opt; do
    case $opt in
        f) FILTER="$OPTARG" ;;
        n) LATEST_N="$OPTARG" ;;
        *) usage ;;
    esac
done

echo "Fetching all tags for $REPO..."

TAGS_LIST=()

while true; do
    RESPONSE=$(curl -s "$URL?page=$PAGE&page_size=$PAGE_SIZE")
    TAGS=$(echo "$RESPONSE" | jq -r '.results[].name')

    if [ -z "$TAGS" ]; then
        break
    fi

    if [ -n "$FILTER" ]; then
        TAGS=$(echo "$TAGS" | grep "$FILTER")
    fi

    TAGS_LIST+=($TAGS)

    PAGE=$((PAGE + 1))
done

# Reverse order to show latest tags first
TAGS_LIST=($(printf "%s\n" "${TAGS_LIST[@]}" | sort -Vr))

# Show only the latest N if specified
if [ "$LATEST_N" -gt 0 ]; then
    TAGS_LIST=("${TAGS_LIST[@]:0:$LATEST_N}")
fi

printf "%s\n" "${TAGS_LIST[@]}"



# filter is so so can be improved
# # latest tag is jq breaking and only giving the checksums 
# ./docker-v2.sh -n 5
# Fetching all tags for kong/kong-gateway...
# jq: error (at <stdin>:1): Cannot iterate over null (null)
# sha256-f3567ba100c01456734c92f7c9ab9f5879bf4e24fa5993033392abaf725b05dc.att
# sha256-f3c5a1727ad29bf3ae69c2c6b890f6c87de10aea2aaec06aae8f648306ef40ec.att
# sha256-ecff3c4778b697f3bde859defd4cc42208c2f3ee7679443dc8b347f2a284ea2b.att
# sha256-e321608e3b46e3fecc209c299c76c60ae1507438fa648002873f7100f582be28.att
# sha256-e95a78cacc5d792f5bcc824af38654032c8de91f71ee3d0b87da3bbf796acf7e.att

