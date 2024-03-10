#!/bin/bash

echo "Upgrading Matomo Analytics 0.1"

# Function to update the status bar
print_bar() {
    local percentage=$1
    local bar_length=$((percentage / 2))
    local bar=$(printf "%-${bar_length}s" "#" | tr ' ' '#')
    printf "[%3d%%] [%-${bar_length}s%s\r" "$percentage" "$bar" "]"
}

# Find Matomo config directory or prompt user
config_dir=$(find /var/www/ -type d -name 'config' -print -quit)
if [ -z "$config_dir" ]; then
    read -p "Enter the path to the Matomo config directory: " config_dir
fi

# Prompt for the temporary directory or default to /tmp
read -p "Enter the path to the temporary directory (e.g., /tmp): " temp_dir
temp_dir=${temp_dir:-/tmp}

# Backup der Konfigurationsdateien
backup_dir="/var/www/"
mkdir -p "$backup_dir"
cp -R "$config_dir"/* "$backup_dir" > /dev/null

# Display ASCII progress bar for backup
total_files=$(find "$config_dir" -type f | wc -l)
copied_files=0
for file in "$config_dir"/*; do
    ((copied_files++))
    if [ "$total_files" -eq 0 ]; then
        percentage=100
    else
        percentage=$((copied_files * 100 / total_files))
    fi
    print_bar $percentage
    sleep 0.5  # Adjust the sleep duration as needed
done

# Herunterladen der neuesten Matomo-Version
wget -q "https://builds.matomo.org/matomo.zip" -P "$temp_dir"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo -e "\nError: Matomo download failed. Please check your internet connection or try again later."
    exit 1
fi

unzip -qo "$temp_dir/matomo.zip" -d /var/www/

rm "$temp_dir/matomo.zip"

# Display ASCII progress bar for download
total_files=$(find "$temp_dir" -type f | wc -l)
copied_files=0
for file in "$temp_dir"/*; do
    ((copied_files++))
    if [ "$total_files" -eq 0 ]; then
        percentage=100
    else
        percentage=$((copied_files * 100 / total_files))
    fi
    print_bar $percentage
    sleep 0.5  # Adjust the sleep duration as needed
done

# Aktualisieren der Matomo-Installation
/var/www/matomo/console core:update

# Berechtigungen anpassen
chmod +w /var/www/matomo/matomo.js
chown www-data:www-data /var/www/matomo/matomo.js

# Display ASCII progress bar for update and permissions
total_files=2  # Assuming two operations (update and permission change)
copied_files=0
for _ in {1..2}; do
    ((copied_files++))
    if [ "$total_files" -eq 0 ]; then
        percentage=100
    else
        percentage=$((copied_files * 100 / total_files))
    fi
    print_bar $percentage
    sleep 0.2  # Adjust the sleep duration as needed
done

echo -e "\nMatomo Upgrade erfolgreich abgeschlossen!"

