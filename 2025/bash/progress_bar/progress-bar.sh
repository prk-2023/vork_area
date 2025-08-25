#!/usr/bin/env bash

#  find cache files recursively and then delete the file and show in progress bar.
#  ------------------------------------------------------------------------------
test-progress-bar() {
    local current=$1
    local len=$2

    local length=50 # length of the bar
    local perc_done=$((current * 100 / len))
    local num_bar=$((perc_done * length / 100))
    echo "$num_bar"

    #echo "processing $current/$len  ($perc_done%)"

    # construct the progress bar like [---->        ]
    local s='['
    local i
    for ((i=0; i < num_bar; i++)); do 
        s+='-'
    done
        s+='>'
    for ((i=num_bar; i < length; i++)); do 
        s+=' '
    done
    s+=']'
    # the below echo will print on a line generating 50 lines to finish theprogress bar
    ##echo "$s $current/$len ($perc_done%)"
    # hack to animate the progress bar on same line:
    # -ne: no newline + interpret escape sequences
    # \r: return carriage to start of the line 
    # \033[K clears to the end of line to avoid leftover text
    echo -ne "$s $current/$len ($perc_done%)\033[K\r"

}

progress-bar() {
    local current=$1
    local len=$2

    local length=50 # length of the bar
    local perc_done=$((current * 100 / len))
    local num_bar=$((perc_done * length / 100))

    local s='['
    local i
    for ((i=0; i < num_bar; i++)); do 
        s+='-'
    done
    s+='>'
    for ((i=num_bar+1; i <= length; i++)); do 
        s+=' '
    done
    s+=']'

    # -ne: no newline + interpret escape sequences
    # \r: return carriage to start of line
    # \033[K clears to the end of the line to avoid leftover text
    echo -ne "$s $current/$len ($perc_done%)\033[K\r"
}

progress-bar-color() {
    local current=$1
    local len=$2

    local length=50
    local perc_done=$((current * 100 / len))
    local num_bar=$((perc_done * length / 100))

    # ANSI color codes
    local RED='\033[31m'
    #local BLUE='\033[34m'
    local BLUE='\033[1;34m'   # BOLD blue
    local RESET='\033[0m'

    # Build progress bar
    local s='['
    local i
    for ((i = 0; i < num_bar; i++)); do
        s+="${RED}-${RESET}"
    done
    if ((num_bar < length)); then
        s+="${BLUE}>${RESET}"
    else
        s+="${RED}-${RESET}"  # Full bar
    fi
    for ((i = num_bar + 1; i <= length; i++)); do
        s+='.'
    done
    s+=']'

    # Clear line (\033[K), move to start (\r)
    echo -ne "$s $current/$len ($perc_done%)\033[K\r"
}
#
echo "Finding Files to delete"
# find . -name '*cache'
# Instead of find we can use the bash builtin as below to get all the files 
shopt -s globstar nullglob  
#  the below line  requires 'shopt' to be define and we add a nullglob ( which would return a null array if 
#  no file is found.
files=(./**/*cache) 
len=${#files[@]}

echo "Found $len files"

# for this example generate files as below 
# mkdir foo bar baz
# touch foo/1.txt
# touch foo/1.jpg
# touch bar/foo-{1..500}-cache 
# touch baz/dont-delete-me
i=0
for file in "${files[@]}"; do 
    sleep 0.001
    #progress-bar "$((i+1))" "$len"  # we pass i+1 as we want to count files from 1 to 500
    progress-bar-color "$((i+1))" "$len"  # we pass i+1 as we want to count files from 1 to 500
    #echo $file 
    ((i++))
done
echo
