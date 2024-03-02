#!/bin/bash

# Initialize progress variables
total_tasks=4
completed_tasks=0

# Function to update and display the progress bar
update_progress() {
    completed_tasks=$((completed_tasks + 1))
    percent=$((completed_tasks * 100 / total_tasks))
    printf "\rProgress: [%-50s] %d%%" $(printf "#%.0s" $(seq 1 $((percent / 2)))) $percent
}

# Function to download and copy a file to its destination
download_and_copy() {
    local url=$1
    local destination=$2

    # Create destination directory if it doesn't exist
    mkdir -p $(dirname "${destination}")
    # Back up the original config
    cp "${destination}" "${destination}.bak"
    # Download the file
    curl -Ls "${url}" -o "${destination}"
    echo -e "\nCopied $(basename "${destination}") to ${destination}"
    update_progress
}

# Example template for adding new configurations
# The following lines are commented out. To use, uncomment and replace placeholders with actual values
# download_and_copy "https://github.com/gunmantheh/<repo>/raw/master/<file_path>" "/desired/path/on/local/system"
# update_progress # Uncomment this line as well when adding a new task

# Neovim configuration
download_and_copy "https://github.com/gunmantheh/linux_configs/raw/master/.vimrc" "${HOME}/.config/nvim/init.vim"

# Tmux configuration
download_and_copy "https://github.com/gunmantheh/linux_configs/raw/master/.tmux.conf" "${HOME}/.tmux.conf"

# ZSH configuration
download_and_copy "https://github.com/gunmantheh/linux_configs/raw/master/.zshrc" "${HOME}/.zshrc"

# lf configuration
download_and_copy "https://github.com/gunmantheh/linux_configs/raw/master/lfrc" "${HOME}/.config/lf/lfrc"
echo -e "\nConfiguration files have been downloaded and copied to their appropriate locations."
