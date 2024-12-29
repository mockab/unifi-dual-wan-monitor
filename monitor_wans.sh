#!/bin/bash

# Set the WAN interface names
WAN1_IFACE="WAN1_INTERFACE"
WAN2_IFACE="WAN2_INTERFACE"

# Define Uptime Kuma Instance URL
UPTIME_KUMA_URL="https://demo.kuma.pet/api/push"

# Define the unique identifier variables for WAN1 and WAN2
WAN1_UPTIME_UID="wan1_unique_identifier"  # Replace with your WAN1 unique identifier
WAN2_UPTIME_UID="wan2_unique_identifier"  # Replace with your WAN2 unique identifier

# Log file
LOG_FILE="/var/log/monitor_wans.log"

# Ensure the log file exists and is writable
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# Log a message with a timestamp
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to get the first IP in the subnet based on cidr
get_first_ip_in_subnet() {
    local ip=$1
    local host_min=$(ipcalc "$ip" | grep HostMin | awk '{print $2}')
    echo "$host_min"
}

# Function to get the current IP for an interface
get_interface_ip() {
    local iface=$1
    local ip=$(ip addr show "$iface" | grep "inet " | awk '{print $2}')
    echo "$ip"
}

# Function to monitor an IP and send a curl request if it is unreachable
monitor_ip() {
    local ip=$1
    local wan_name=$2
    local unique_identifier=$3
    local curl_url="${UPTIME_KUMA_URL}/${unique_identifier}?status=up&msg=IP+Unreachable&ping="

    if ! ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
        log_message "Ping to $wan_name ($ip) failed. Sending status update."
        curl -sk "${curl_url}" -o /dev/null
    else
        log_message "Ping to $wan_name ($ip) successful."
    fi
}

# Function to send status update when WAN IP is not found
send_ip_not_found_status() {
    local wan_name=$1
    local unique_identifier=$2
    local curl_url="${UPTIME_KUMA_URL}/${unique_identifier}?status=up&msg=No+IP+found&ping=0"

    log_message "$wan_name IP not found. Sending status update."
    curl -sk "${curl_url}" -o /dev/null
}

# Get the current IPs for WAN1 and WAN2
WAN1_IP=$(get_interface_ip "$WAN1_IFACE")
WAN2_IP=$(get_interface_ip "$WAN2_IFACE")

# Monitor WAN1
if [[ -n "$WAN1_IP" ]]; then
    WAN1_FIRST_IP=$(get_first_ip_in_subnet "$WAN1_IP")
    monitor_ip "$WAN1_FIRST_IP" "wan1" "$WAN1_UPTIME_UID"
else
    send_ip_not_found_status "WAN1" "$WAN1_UPTIME_UID"
fi

# Monitor WAN2
if [[ -n "$WAN2_IP" ]]; then
    WAN2_FIRST_IP=$(get_first_ip_in_subnet "$WAN2_IP")
    monitor_ip "$WAN2_FIRST_IP" "wan2" "$WAN2_UPTIME_UID"
else
    send_ip_not_found_status "WAN2" "$WAN2_UPTIME_UID"
fi
