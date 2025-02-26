#!/bin/bash

if [ $# -ne 2 ]; then
    echo "missing parameters."
    exit 1
fi

filesdir=$1
searchstr=$2

if [ ! -d "$filesdir" ]; then
    echo "wrong directory."
    exit 1
fi

filesNum=$(find "$filesdir" -type f | wc -l)
linesNum=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)
echo "The number of files are $filesNum and the number of matching lines are $linesNum"

