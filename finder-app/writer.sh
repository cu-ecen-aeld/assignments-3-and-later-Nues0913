#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Missing parameters."
    exit 1
fi

writefile=$1
writestr=$2

mkdir -p "$(dirname "$writefile")"

echo "$writestr" > "$writefile"
if [ $? -ne 0 ]; then
    echo "Unable to write to file $writefile"
    exit 1
fi

