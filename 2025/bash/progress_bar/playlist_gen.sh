#!/bin/bash

# Function to print a colored progress bar
progress-bar-color() {
    local current=$1
    local total=$2

    local length=50
    local perc_done=$((current * 100 / total))
    local num_bar=$((perc_done * length / 100))

    local RED='\033[31m'
    local BLUE='\033[1;34m'
    local RESET='\033[0m'

    local s='['
    for ((i = 0; i < num_bar; i++)); do
        s+="${RED}-${RESET}"
    done
    if ((num_bar < length)); then
        s+="${BLUE}>${RESET}"
    else
        s+="${RED}-${RESET}"
    fi
    for ((i = num_bar + 1; i <= length; i++)); do
        s+='.'
    done
    s+=']'

    echo -ne "$s $current/$total ($perc_done%)\033[K\r"
}

# Initialize the playlist file
echo "#EXTM3U" > playlist.m3u

# Collect matching video files into an array
mapfile -t files < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \) | sort)

total=${#files[@]}
if (( total == 0 )); then
    echo "No video files found."
    exit 1
fi

echo "Generating playlist for $total files..."

# Loop through each file and build the playlist
##for ((i=0; i<total; i++)); do
for i in "${!files[@]}"; do
    file="${files[i]}"
    filename=$(basename "$file")
    
    echo "#EXTINF:0,$filename" >> playlist.m3u
    echo "$filename" >> playlist.m3u

    # Optional delay for demo purposes
    sleep 0.01
    progress-bar-color "$((i + 1))" "$total"
done

# Final line to move to a new line after progress bar
echo -e "\nDone: playlist.m3u created with $total entries."
