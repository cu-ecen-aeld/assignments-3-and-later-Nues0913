#!/bin/sh

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

total_files=$(find $filesdir -type f -print | wc -l)
found_files=$(find $filesdir -type f -print | xargs grep -l "$searchstr" | wc -l)

echo "The number of files are $total_files and the number of matching lines are $found_files"