#!/bin/bash

# Processing all text files in the current directory
for file in *.txt; do
    # Skip if no txt files exist
    if [ "$file" = "*.txt" ]; then
        echo "No text files found."
        break
    fi

    # Skip empty files
    if [ ! -s "$file" ]; then
        echo " Skipping empty file"
        continue
    fi

    echo "Processing #$file..."

    # Count lines, words and characters
    lines=$(wc -l < "$file")
    words=$(wc -w < "$file")
    chars=$(wc -c < "$file")


    echo " Lines: $lines"
    echo " Words: $words"
    echo " Characters: $chars"
done 
