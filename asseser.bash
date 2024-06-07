#!/bin/bash
# OSTMM OPST-II Script 
# Authors: Miguel Montag, Leo Pierren, Tomislav Tofiloski
# Date: 07.06.2024

# Directory for storing output files
apt install gobuster -y

OUTPUT_DIR="00-scan"

# Check if the scan directory exists
if [ -d "$OUTPUT_DIR" ]; then
    # If the directory exists, find the highest enumerated directory and increment
    HIGHEST_DIR=$(ls -d [0-9]*-scan/ | sort -Vr | head -n 1)
    LAST_NUMBER=$(echo "$HIGHEST_DIR" | grep -oE '^[0-9]+')
    NEXT_NUMBER=$((LAST_NUMBER + 1))
    OUTPUT_DIR=$(printf "%02d-scan" "$NEXT_NUMBER")
fi

# Create the scan directory
mkdir -p "$OUTPUT_DIR"

ICMP_OUTPUT_FILE="$OUTPUT_DIR/icmp_scan_results.txt"
TCP_OUTPUT_FILE="$OUTPUT_DIR/tcp_scan_results.txt"
UDP_OUTPUT_FILE="$OUTPUT_DIR/udp_scan_results.txt"
AGGRESIVE_OUTPUT_FILE="$OUTPUT_DIR/agressive_scan_results.txt"
DIRBUSTER_OUTPUT_FILE="$OUTPUT_DIR/dirbuster_results.txt"

# Function to execute a command and save its output to a file
run_command() {
    local cmd="$1"
    local outfile="$2"
    {
        echo "# Command used: $cmd"
        echo "# Output:"
        eval "$cmd"
        echo ""
    } >> "$outfile"
}

# Prompt the user to enter the target network
read -p "Enter the target network (e.g., 192.168.1.0/24 or example.com): " TARGETNETWORK

# Visibility:
# ICMP Scans save to ICMP_OUTPUT_FILE
run_command "fping -a -g $TARGETNETWORK" "$ICMP_OUTPUT_FILE"
run_command "nmap -sP $TARGETNETWORK" "$ICMP_OUTPUT_FILE"

# Prompt the user to enter the target system IP
read -p "Enter the target system IP (e.g., 192.168.1.xy): " TARGET

# Port Scans
# TCP Scans save to TCP_OUTPUT_FILE
run_command "nmap -p- -T5 $TARGET" "$TCP_OUTPUT_FILE"
run_command "nmap -sV $TARGET" "$TCP_OUTPUT_FILE"

# UDP Scan save to UDP_OUTPUT_FILE
run_command "nmap -sU $TARGET" "$UDP_OUTPUT_FILE"

# Aggressive Scan save to AGGRESIVE_OUTPUT_FILE
run_command "nmap -A $TARGET" "$AGGRESIVE_OUTPUT_FILE"

# Banner grabbing
run_command "nmap --script banner $TARGET" "$AGGRESIVE_OUTPUT_FILE"

# Vulnerability scan
run_command "nmap -sV --script vulners $TARGET" "$AGGRESIVE_OUTPUT_FILE"

# Prompt the user to enter the target system and web port for dirbusting
read -p "Enter the target system and web port (Format: IP:Port): " WEB_TARGET

# Exploit save to DIRBUSTER_OUTPUT_FILE
run_command "gobuster dir -u http://$WEB_TARGET -w /usr/share/wordlists/dirb/big.txt" "$DIRBUSTER_OUTPUT_FILE"