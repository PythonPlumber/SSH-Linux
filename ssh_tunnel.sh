#!/bin/bash

# Configuration
CONFIG_FILE="ssh_config.json"
LOG_FILE="ssh_tunnel.log"

# Read SSH configuration from JSON file
read_config() {
  local profile_name=$1
  jq -r --arg profile "$profile_name" '.profiles[] | select(.name == $profile)' "$CONFIG_FILE"
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
  local port=$(jq -r '.port' <<< "$config")
  local username=$(jq -r '.username' <<< "$config")
  local identity_file=$(jq -r '.identity_file' <<< "$config")
  local password=$(jq -r '.password' <<< "$config")
  local local_ports=$(jq -r '.local_ports | join(",")' <<< "$config")
  local remote_ports=$(jq -r '.remote_ports | join(",")' <<< "$config")

  log "Starting SSH tunnel for profile: $profile_name"

  if [ -n "$identity_file" ]; then
    autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "ExitOnForwardFailure yes" \
      -i "$identity_file" -L "$local_ports:localhost:$remote_ports" -p "$port" "$username@$host" >> "$LOG_FILE" 2>&1
  else
    autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "ExitOnForwardFailure yes" \
      -L "$local_ports:localhost:$remote_ports" -p "$port" "$username@$host" >> "$LOG_FILE" 2>&1
  fi

  log "SSH tunnel started for profile: $profile_name. Local ports: $local_ports, Remote ports: $remote_ports"
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
  local port=$(jq -r '.port' <<< "$config")
  local username=$(jq -r '.username' <<< "$config")

  log "Stopping SSH tunnel for profile: $profile_name"

  autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "ExitOnForwardFailure yes" \
    -O "exit" -p "$port" "$username@$host" >> "$LOG_FILE" 2>&1

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

# Check if the log file exists, create it if not
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
fi

# Check the number of arguments
if [ "$#" -ne 2 ]; then
  echo "Invalid number of arguments. Usage: $0 <profile_name> <start|stop>"
  exit 1
fi

# Parse the command-line arguments
profile_name=$1
action=$2

# Perform the requested action
case "$action" in
  "start") start_tunnel "$profile_name" ;;
  "stop") stop_tunnel "$profile_name" ;;
  *) echo "Invalid action. Please use 'start' or 'stop'." ;;
esac
