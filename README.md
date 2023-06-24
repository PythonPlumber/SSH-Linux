# SSH Tunneling Script

This script allows you to easily manage SSH tunneling on your Linux system. It reads SSH configuration from a JSON file and starts or stops SSH tunnels based on the specified profiles.

## Prerequisites

- Linux system
- `jq` tool installed (to parse the JSON configuration file)
- SSH access to the remote servers

## Configuration

1. Open the `ssh_config.json` file and update it with your SSH profiles.
2. Each profile should include the following information:
   - `name`: Profile name for identification
   - `host`: SSH server host or IP address
   - `username`: SSH username
   - `password`: SSH password
   - `port`: SSH port number (default: 22)

## Usage

1. Make the script executable by running the following command:
   ```bash
   chmod +x ssh_tunnel.sh
   ```

2. Start an SSH tunnel using a profile:
   ```
   ./ssh_tunnel.sh <profile_name> start
   ```
   Replace <profile_name> with the name of the profile defined in the ssh_config.json file.

3. Stop an SSH tunnel using a profile:
  ```
  ./ssh_tunnel.sh <profile_name> stop
  ```
  Replace <profile_name> with the name of the profile defined in the ssh_config.json file.

# Logging

The script logs its activities to the `ssh_tunnel.log` file in the same directory. You can review this log file to track the start and stop events of the SSH tunnels.

To enable or disable logging, you can comment or uncomment the `log` function calls within the script

# License
This script is released under the MIT License.
