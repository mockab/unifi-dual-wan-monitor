#!/bin/bash

# Define the raw GitHub URL and the output file name
RAW_URL="https://raw.githubusercontent.com/mockab/unifi-dual-wan-monitor/refs/heads/main/monitor_wans.sh"
OUTPUT_FILE="/tmp/setup_monitor_wans.sh"

# Define the replacements in key-value pairs (original -> replacement)
declare -A REPLACEMENTS=(
    ["demo.kuma.pet"]="replacement_value_1"
    ["wan1_unique_identifier"]="replacement_value_2"
    ["wan2_unique_identifier"]="replacement_value_3"
)

# Download the raw GitHub script
echo "Downloading the script from $RAW_URL..."
curl -sSL "$RAW_URL" -o "$OUTPUT_FILE"

# Check if the file was downloaded successfully
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "Error: Failed to download the script."
    exit 1
fi

echo "Downloaded script to $OUTPUT_FILE."

# Use sed to replace the entries
echo "Modifying the script with the specified replacements..."
for ORIGINAL in "${!REPLACEMENTS[@]}"; do
    REPLACEMENT=${REPLACEMENTS[$ORIGINAL]}
    sed -i "s|$ORIGINAL|$REPLACEMENT|g" "$OUTPUT_FILE"
    echo "Replaced '$ORIGINAL' with '$REPLACEMENT'."
done

# Make the modified script executable
chmod +x "$OUTPUT_FILE"

# Run the modified script in the background
echo "Running the modified script in the background..."
nohup "$OUTPUT_FILE" >/dev/null 2>&1 &

# Notify the user and exit
echo "The modified script is running in the background (PID: $!)."
