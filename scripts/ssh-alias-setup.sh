#!/bin/bash



windows_username=$(cmd.exe /C echo %USERNAME% | tr -d '\r')

# Check if the Windows username was retrieved successfully
if [ -z "$windows_username" ]; then
    echo "Error: Unable to determine Windows username."
    exit 1
fi

# Define the location of the PowerShell alias file on Windows (accessible from WSL)
alias_file="/mnt/c/Users/$windows_username/scripts/ps-alias-functions.ps1"

# Overwrite the alias file each time the script is run
echo "# PowerShell aliases for SSH" > "$alias_file"

domain="cirdanultra.com"

# Array of server information: 'username@server' 'alias'
servers=(
    "dbtest@snipefish sf"
    "dbtest@snipefishr8 sfr8"
    "dbtest@devrhel8 devr8"
    "dbtest@test485r8 test485r8"
    "dbtest@test490 test490"
    "dbtest@test48r8 test48r8"
    "dbtest@test48dpr8 test48dpr8"
    "dbtest@dev485r8 dev485r8"
    "dbtest@qa485r8 qa485r8"
    "dbtest@auto auto"
)

# SSH password
password="vis48ion"

if ! command -v sshpass &> /dev/null; then
    echo "sshpass not found. Installing sshpass..."
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

for server_alias in "${servers[@]}"; do
    # Split the string into user@server_base and alias
    user_and_server_base=$(echo $server_alias | cut -d' ' -f1)
    alias=$(echo $server_alias | cut -d' ' -f2)

    user_and_server="${user_and_server_base}.${domain}"
    
    echo "Copying SSH key to $user_and_server"
    sshpass -p "$password" ssh-copy-id -i /mnt/c/Users/$windows_username/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $user_and_server
    
    # Create a PowerShell function for the alias
    powershell_function="function $alias { ssh -o StrictHostKeyChecking=no $user_and_server }"
    
    echo "Adding PowerShell alias for $alias"
    echo $powershell_function >> "$alias_file"
done

echo "All SSH keys copied and PowerShell aliases created in $alias_file."
