#!/bin/bash

# Configuration
CONFIG_FILE="ssh_config.json"
LOG_FILE="ssh_tunnel.log"

# Read SSH configuration from JSON file
read_config() {
  local profile_name=$1
  jq -r --arg profile "$profile_name" '.profiles[] | select(.name == $profile) | {host, username, password, port}' "$CONFIG_FILE"
}

# Start SSH tunnel
start_tunnel() {
  local profile_name=$1
  local config=$(read_config "$profile_name")

  if [ -z "$config" ]; then
    log "Invalid profile name: $profile_name"
    exit 1
  fi

  local host=$(jq -r '.host' <<< "$config")
  local username=$(jq -r '.username' <<< "$config")
  local password=$(jq -r '.password' <<< "$config")
  local port=$(jq -r '.port' <<< "$config")

  log "Starting SSH tunnel for profile: $profile_name"

  {
    echo "◈──────────────────◈"
    echo "©️ 🕸 Spider SSH 🕸"
    echo "◈──────────────────◈"
  } | sshpass -p "$password" ssh -N -f -L 8080:localhost:80 -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" -o "TCPKeepAlive=yes" -o "GatewayPorts=yes" -o "StreamLocalBindUnlink=yes" -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" -o "TCPKeepAlive=yes" -o "GatewayPorts=yes" -o "StreamLocalBindUnlink=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "DynamicForward=socks5://localhost:1080" -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" -o "TCPKeepAlive=yes" -o "GatewayPorts=yes" -o "StreamLocalBindUnlink=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -p "$port" "$username@$host" -D "$sni_bughost" >> "$LOG_FILE" 2>&1

  log "SSH tunnel started for profile: $profile_name"
}

# Stop SSH tunnel
stop_tunnel() {
  local profile_name=$1
  local config=$(read_config "$profile_name")

  if [ -z "$config" ]; then
    log "Invalid profile name: $profile_name"
    exit 1
  fi

  local host=$(jq -r '.host' <<< "$config")
  local username=$(jq -r '.username' <<< "$config")
  local port=$(jq -r '.port' <<< "$config")

  log "Stopping SSH tunnel for profile: $profile_name"

  sshpass -p "$password" ssh -O "exit" -p "$port" "$username@$host" >> "$LOG_FILE" 2>&1

  log "SSH tunnel stopped for profile: $profile_name"
}

# Log messages to the log file
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Main script

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "SSH configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Check the number of arguments
if [ "$#" -ne 2 ]; then
  echo "Invalid number of arguments. Usage: $0 <profile_name> <start|stop>"
  exit 1
fi

# Parse the command-line arguments
profile_name=$1
action=$2

# Load SNI and BugHost values from the configuration file
sni_bughost=$(jq -r '.sni_bughost' "$CONFIG_FILE")

# Perform the requested action
case "$action" in
  "start") start_tunnel "$profile_name" ;;
  "stop") stop_tunnel "$profile_name" ;;
  *) echo "Invalid action. Please use 'start' or 'stop'." ;;
esac
