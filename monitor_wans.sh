#!/bin/bash

# Set the WAN interface names
WAN1_IFACE="ppp0"
WAN2_IFACE="eth8"

# Define Uptime Kuma Instance URL
UPTIME_KUMA_URL="https://demo.kuma.pet/api/push"

# Define the unique identifier variables for WAN1 and WAN2
WAN1_UPTIME_UID="wan1_unique_identifier"  # Replace with your WAN1 unique identifier
WAN2_UPTIME_UID="wan2_unique_identifier"  # Replace with your WAN2 unique identifier

# Function to get the first IP in the /24 subnet (always x.x.x.1)
get_first_ip_in_subnet() {
    local ip=$1
    local first_ip=$(echo "$ip" | awk -F'.' '{print $1"."$2"."$3".1"}')
    echo "$first_ip"
}

# Function to get the current IP for an interface
get_interface_ip() {
    local iface=$1
    local ip=$(ip addr show "$iface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "$ip"
}

# Function to monitor an IP and send a curl request if it is unreachable
monitor_ip() {
    local ip=$1
    local wan_name=$2
    local unique_identifier=$3
    local curl_url="${UPTIME_KUMA_URL}/${unique_identifier}?status=up&msg=OK&ping="

    # Ping the IP
    if ! ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
        echo "Ping to $wan_name ($ip) failed. Sending status update."
        curl -sk "${curl_url}" -o /dev/null
    else
        echo "Ping to $wan_name ($ip) successful."
    fi
}

# Infinite monitoring loop
while true; do
    # Get the current IPs for WAN1 and WAN2
    WAN1_IP=$(get_interface_ip "$WAN1_IFACE")
    WAN2_IP=$(get_interface_ip "$WAN2_IFACE")

    # If a valid IP is found, calculate the first IP in the subnet (x.x.x.1)
    if [[ -n "$WAN1_IP" ]]; then
        WAN1_FIRST_IP=$(get_first_ip_in_subnet "$WAN1_IP")
        monitor_ip "$WAN1_FIRST_IP" "wan1" "$WAN1_UPTIME_UID"
    else
        echo "WAN1 IP not found. Skipping..."
    fi

    if [[ -n "$WAN2_IP" ]]; then
        WAN2_FIRST_IP=$(get_first_ip_in_subnet "$WAN2_IP")
        monitor_ip "$WAN2_FIRST_IP" "wan2" "$WAN2_UPTIME_UID"
    else
        echo "WAN2 IP not found. Skipping..."
    fi

    # Wait for 30 seconds before the next check (allowing time for IP reassignment via DHCP)
    sleep 30
done
