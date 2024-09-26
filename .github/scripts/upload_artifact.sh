#!/bin/bash

set -e

file_path="$1"
artifact_name="$2"

if [ -z "$file_path" ] || [ -z "$artifact_name" ]; then
    echo "Usage: $0 <file_path> <artifact_name>"
    exit 1
fi

max_retries=5
retry_delay=10

for i in $(seq 1 $max_retries); do
    echo "Attempt $i to upload $artifact_name"
    if curl -X POST \
         -H "Authorization: token $GITHUB_TOKEN" \
         -H "Content-Type: application/zip" \
         --data-binary "@$file_path" \
         "https://uploads.github.com/repos/$GITHUB_REPOSITORY/actions/artifacts" \
         -o response.json; then

        echo "Upload successful"
        cat response.json
        rm response.json
        exit 0
    else
        echo "Upload failed. Retrying in $retry_delay seconds..."
        sleep $retry_delay
    fi
done

echo "Failed to upload $artifact_name after $max_retries attempts"
exit 1
