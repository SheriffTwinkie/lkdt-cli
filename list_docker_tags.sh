#!/bin/bash

# Example: ./list_docker_tags.sh -f "^3\.[0-9]+\.[0-9]+\.[0-9]+$" -s

# Docker repository to fetch tags from
REPO="kong/kong-gateway"
URL="https://hub.docker.com/v2/repositories/$REPO/tags/"
PAGE_SIZE=100
FILTER=""
LATEST_N=0
OUTPUT_FILE=""
JSON_OUTPUT=false
SHOW_PROGRESS=true
STABLE_ONLY=false
VERBOSE=false
SORT_DESC=true  # Default to newest first
MAX_PARALLEL_REQUESTS=5  # Adjust based on system capabilities
MAX_RETRIES=3  # Number of retries for network failures
RETRY_DELAY=5  # Seconds to wait before retrying

# Colors for readability
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m"  # No color

usage() {
    echo -e "${CYAN}Usage:${NC} $0 [options]"
    echo "  -f, --filter filter      Only show tags matching the given filter (supports regex)"
    echo "  -n, --latest latest_n    Show only the latest N tags"
    echo "  -j, --json               Output results in JSON format"
    echo "  -o, --output filename    Save results to the specified file"
    echo "  -s, --stable             Show only stable (non-RC, non-beta) tags"
    echo "  --sort asc|desc          Sort results in ascending or descending order (default: desc)"
    echo "  -q, --quiet              Hide progress indicator"
    echo "  -v, --verbose            Show API call details for debugging"
    echo "  -h, --help               Show this help message"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--filter) FILTER="$2"; shift 2 ;;
        -n|--latest) LATEST_N="$2"; shift 2 ;;
        -j|--json) JSON_OUTPUT=true; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -s|--stable) STABLE_ONLY=true; shift ;;
        --sort)
            if [[ "$2" == "asc" ]]; then
                SORT_DESC=false
            else
                SORT_DESC=true
            fi
            shift 2 ;;
        -q|--quiet) SHOW_PROGRESS=false; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option:${NC} $1"; usage ;;
    esac
done

echo -e "${CYAN}Fetching tags for ${GREEN}$REPO${NC}..."

# Function to make API requests with retries
fetch_page() {
    local page=$1
    local attempt=1
    local response

    while [[ $attempt -le $MAX_RETRIES ]]; do
        response=$(curl -s --retry $MAX_RETRIES --retry-delay $RETRY_DELAY "$URL?page=$page&page_size=$PAGE_SIZE")

        # check if API returned valid JSON
        if jq -e . <<<"$response" >/dev/null 2>&1; then
            # Handle rate limiting (429 Too Many Requests)
            if echo "$response" | jq -e 'select(.message=="Too Many Requests")' >/dev/null; then
                echo -e "${YELLOW}Rate limited! Waiting $RETRY_DELAY seconds before retrying... (Attempt $attempt)${NC}"
                sleep $RETRY_DELAY
                ((attempt++))
                continue
            fi

            # Extract tags if successful
            echo "$response" | jq -r '.results[].name'
            return
        else
            echo -e "${RED}Invalid response from Docker Hub (Attempt $attempt)${NC}"
        fi

        ((attempt++))
        sleep $RETRY_DELAY
    done

    echo -e "${RED}Failed to fetch page $page after $MAX_RETRIES attempts.${NC}" >&2
    return 1
}

export -f fetch_page
export URL
export PAGE_SIZE
export MAX_RETRIES
export RETRY_DELAY

# Get total number of pages
TOTAL_COUNT=$(curl -s "$URL?page=1&page_size=$PAGE_SIZE" | jq -r '.count // 0')
TOTAL_PAGES=$(( (TOTAL_COUNT + PAGE_SIZE - 1) / PAGE_SIZE ))

if [[ $TOTAL_COUNT -eq 0 ]]; then
    echo -e "${RED}No tags found or API request failed.${NC}"
    exit 1
fi

# Debugging info
$VERBOSE && echo -e "${YELLOW}Total pages to fetch: $TOTAL_PAGES${NC}"

SORT_FLAG="-Vru"
if ! $SORT_DESC; then
    SORT_FLAG="-Vu"
fi

# Fetch all pages in parallel
# Also now sorting in reverse so the output is newest to oldest versioning
TAGS_LIST=$(seq 1 $TOTAL_PAGES | xargs -I {} -P $MAX_PARALLEL_REQUESTS bash -c 'fetch_page "$@"' _ {} | sort $SORT_FLAG)

# Apply filters
if [ -n "$FILTER" ]; then
    TAGS_LIST=$(echo "$TAGS_LIST" | grep -E -i "$FILTER")
fi

if $STABLE_ONLY; then
    TAGS_LIST=$(echo "$TAGS_LIST" | grep -E -v '(rc|beta|alpha)')
fi

# Show only the latest N if specified
if [ "$LATEST_N" -gt 0 ]; then
    TAGS_LIST=$(echo "$TAGS_LIST" | head -n "$LATEST_N")
fi

# Convert to JSON if requested
if $JSON_OUTPUT; then
    JSON_RESULT=$(echo "$TAGS_LIST" | jq -R . | jq -s .)
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$JSON_RESULT" > "$OUTPUT_FILE"
        echo -e "${CYAN}Results saved to ${GREEN}$OUTPUT_FILE${NC} (JSON format)"
    else
        echo "$JSON_RESULT"
    fi
else
    # Print results normally
    if [ -z "$TAGS_LIST" ]; then
        echo -e "${RED}No tags found matching your criteria.${NC}"
    else
        echo "$TAGS_LIST"
    fi
    
    # Save to file if requested
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$TAGS_LIST" > "$OUTPUT_FILE"
        echo -e "${CYAN}Results saved to ${GREEN}$OUTPUT_FILE${NC}"
    fi
fi





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




# works but dont like default filter to show oldest, should show newest
# ./docker-v3.sh -n 5 -f 3.9
# Fetching all tags for kong/kong-gateway...
# 3.4.1.0-20230929-amazonlinux-2
# 3.4.1.0-20230929-amazonlinux-2023
# 3.4.1.0-20230929-debian
# 3.4.1.0-20230929-rhel
# 3.4.1.0-20230929-rhel-fips
# rumpus@tehKongirator:~/Downloads$ ./docker-v3.sh -n 5 -f 3.9.1
# Fetching all tags for kong/kong-gateway...
# 3.9.1.0
# 3.9.1.0-20250311-amazonlinux-2
# 3.9.1.0-20250311-amazonlinux-2023
# 3.9.1.0-20250311-debian
# 3.9.1.0-20250311-rhel
# filter seems a little goofy as well 

# still giving some checksum or uuid
#  ./docker-v3.sh -n 10 -f 3.9.1
# Fetching all tags for kong/kong...
# 0a06c9eff0527cb943099184c6839cd3c66bb5a5
# 0a06c9eff0527cb943099184c6839cd3c66bb5a5-alpine
# 0a06c9eff0527cb943099184c6839cd3c66bb5a5-debian
# 0a06c9eff0527cb943099184c6839cd3c66bb5a5-rhel
# 0a06c9eff0527cb943099184c6839cd3c66bb5a5-ubuntu
# 00b4a32eb33f9511e7cf21c17d4c1042b72026d6
# 00b4a32eb33f9511e7cf21c17d4c1042b72026d6-ubuntu
# 0d55ec53c3f996e3e80d2270f075250399f136b9
# 0d55ec53c3f996e3e80d2270f075250399f136b9-ubuntu
# 0febfe60acf9122c87a15962536606bc38971df8



# filter still a little off 
# either not working or giving back checksum/UUIDs
# json kinda works, gives brackets which im not sure is correct?
# no open/close {}
# file output save works just fine 
# help menu works

# the filter and latest counter are still getting oldes to newest
# still need to swap that 


# still need to fix filtering, regex is a little off
# the -v is pretty cool, 