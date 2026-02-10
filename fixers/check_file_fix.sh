#!/bin/sh

# Check if a filename was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILENAME="$1"

# Check in parent directory
if [ -f "../$FILENAME" ]; then
    echo "Found in parent directory: ../$FILENAME"
    echo "no issues!"
    exit 0
fi

# Check in grandparent directory
if [ -f "../../$FILENAME" ]; then
    echo "Found in grandparent directory: ../../$FILENAME"
    cp ../../$FILENAME -d ../$FILENAME
    echo "done copying, no issues!"
    exit 0
fi

# File not found in either directory
echo "File '$FILENAME' not found in ../ or ../../"
exit 1
