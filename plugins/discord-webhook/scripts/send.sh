#!/usr/bin/env bash
# Discord webhook sender — curl wrapper
# Usage: send.sh <webhook_url> <payload_file> [--file <path>]
#
# <payload_file>: JSON file containing the Discord message payload
# --file <path>: optional file attachment (sent as multipart/form-data)
#
# stdout: HTTP response body (if any) + status code on last line
# exit code: 0 if HTTP 2xx, 1 otherwise

set -euo pipefail

webhook_url="${1:?Usage: send.sh <webhook_url> <payload_file> [--file <path>]}"
payload_file="${2:?Usage: send.sh <webhook_url> <payload_file> [--file <path>]}"

# Validate inputs
if [ ! -f "$payload_file" ]; then
    echo "ERROR: payload file not found: $payload_file" >&2
    exit 1
fi

# Parse optional --file argument
attach_file=""
shift 2
while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            attach_file="${2:?--file requires a path argument}"
            if [ ! -f "$attach_file" ]; then
                echo "ERROR: attachment file not found: $attach_file" >&2
                exit 1
            fi
            shift 2
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Temp files for response
tmp_body=$(mktemp)
tmp_headers=$(mktemp)
trap 'rm -f "$tmp_body" "$tmp_headers"' EXIT

# Send request
# NOTE: -w (write-out) causes exit code 43 on Windows Schannel due to TLS
# renegotiation. Use -D (dump headers) + parse instead.
if [ -z "$attach_file" ]; then
    # Text-only message
    curl -s -o "$tmp_body" -D "$tmp_headers" \
        -H "Content-Type: application/json" \
        -d "@${payload_file}" \
        "$webhook_url" 2>/dev/null
else
    # Message with file attachment (multipart/form-data)
    curl -s -o "$tmp_body" -D "$tmp_headers" \
        -F "payload_json=<${payload_file}" \
        -F "file=@${attach_file}" \
        "$webhook_url" 2>/dev/null
fi

curl_exit=$?
if [ $curl_exit -ne 0 ]; then
    echo "ERROR: curl failed with exit code $curl_exit" >&2
    exit 1
fi

# Extract HTTP status code from headers
http_code=$(awk '/^HTTP\// { code=$2 } END { print code }' "$tmp_headers")
body=$(cat "$tmp_body")

# Output body if present
[ -n "$body" ] && echo "$body"

# Report status
if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    echo "$http_code"
    exit 0
else
    echo "${http_code:-000}" >&2
    exit 1
fi
