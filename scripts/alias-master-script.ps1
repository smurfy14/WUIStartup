# Functions to Check WSL Installation Status

# Function to check if WSL is installed
function Is-WSLInstalled {
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    return $wslFeature.State -eq "Enabled"
}

# Function to check if Virtual Machine Platform is enabled
function Is-VirtualMachinePlatformEnabled {
    $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    return $vmpFeature.State -eq "Enabled"
}

# Function to check if a reboot is required
function Is-RebootPending {
    $rebootPending = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
    return $rebootPending -ne $null
}

# Function to check if Ubuntu is installed in WSL
function Is-UbuntuInstalled {
    try {
        $distroList = wsl --list --quiet
        return $distroList -contains "Ubuntu"
    } catch {
        return $false
    }
}

# Function to check if WSL default distribution is running
function Is-WSLRunning {
    $wslProcesses = wsl --list --running
    return $wslProcesses -contains "Ubuntu"
}

# Begin Script

# Step 1: Install WSL if not installed
$rebootNeeded = $false

if (-not (Is-WSLInstalled)) {
    Write-Host "Enabling Windows Subsystem for Linux..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $rebootNeeded = $true
}

if (-not (Is-VirtualMachinePlatformEnabled)) {
    Write-Host "Enabling Virtual Machine Platform..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $rebootNeeded = $true
}

if ($rebootNeeded -or (Is-RebootPending)) {
    Write-Host "A system reboot is required. Please reboot your system and re-run the script after reboot."
    # Uncomment the next line to force an automatic reboot
    # Restart-Computer -Force
    exit
}

# Set WSL 2 as default version
wsl --set-default-version 2
wsl --update

# Step 2: Install Ubuntu if not installed
if (-not (Is-UbuntuInstalled)) {
    Write-Host "Ubuntu is not installed in WSL. Installing Ubuntu..."
    wsl --install -d Ubuntu

    # Wait for Ubuntu to be installed
    Write-Host "Waiting for Ubuntu to be installed..."
    do {
        Start-Sleep -Seconds 5
    } until (Is-UbuntuInstalled)

    Write-Host "Ubuntu installation completed."
}

# Set Ubuntu as the default distribution
Write-Host "Setting Ubuntu as the default WSL distribution..."
wsl --set-default Ubuntu

# Step 3: Launch Ubuntu to complete setup
if (-not (Is-WSLRunning)) {
    Write-Host "Launching Ubuntu to complete setup..."
    Start-Process -FilePath "wsl.exe" -ArgumentList "-d Ubuntu" -WindowStyle Normal
    Write-Host "Please complete the initial Ubuntu setup (create UNIX username and password)."
}

# Wait for the user to complete the setup
Write-Host "Waiting for you to complete the Ubuntu setup..."
do {
    # Try to run a simple command in WSL to check if setup is complete
    try {
        $userName = wsl -d Ubuntu echo \$USER
        $setupComplete = $userName -ne ""
    } catch {
        $setupComplete = $false
    }
    Start-Sleep -Seconds 5
} until ($setupComplete)

Write-Host "Ubuntu setup complete."

# Part 1: Update PowerShell $PROFILE

# Define the code to add to the $PROFILE
$codeToAdd = @'
if (Test-Path "$env:USERPROFILE\scripts\ps-alias-functions.ps1") {
    . "$env:USERPROFILE\scripts\ps-alias-functions.ps1"
}
'@

# Get the path to the PowerShell profile
$profilePath = $PROFILE

# Ensure the profile file exists
if (-not (Test-Path $profilePath)) {
    # Create an empty profile file
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

# Read the contents of the profile
$profileContent = Get-Content $profilePath -Raw

# If $profileContent is $null, set it to an empty string
if ($profileContent -eq $null) {
    $profileContent = ""
}

# Check if the code block is already present using .Contains()
if (-not $profileContent.Contains($codeToAdd.Trim())) {
    Write-Host "Code block not found in $PROFILE. Adding it now."
    Add-Content -Path $profilePath -Value "`n$codeToAdd`n"
} else {
    Write-Host "Code block already exists in $PROFILE."
}

# Create SSH key if it doesn't exist
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
$sshDir = "$env:USERPROFILE\.ssh"

# Ensure the .ssh directory exists
if (-not (Test-Path -Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "Created directory: $sshDir"
}

# Check if an SSH key already exists
if (Test-Path -Path $sshKeyPath) {
    Write-Host "An SSH key already exists at $sshKeyPath."
} else {
    # Generate an SSH key with no passphrase
    ssh-keygen -f $sshKeyPath -N ''
    Write-Host "SSH key generated at $sshKeyPath."
}

# Ensure ~/.ssh exists in WSL
Write-Host "Ensuring ~/.ssh directory exists in WSL..."
wsl -d Ubuntu mkdir -p ~/.ssh
wsl -d Ubuntu chmod 700 ~/.ssh

# Part 2: Execute the Bash Script on WSL

# Get the user's home directory
$userProfile = $env:USERPROFILE

# Path to your Bash script on Windows
$bashScriptPathWindows = "$userProfile\scripts\WUIStartup\scripts\ssh-alias-setup.sh"

# Check if the bash script file exists
if (-not (Test-Path $bashScriptPathWindows)) {
    Write-Host "The script file does not exist at $bashScriptPathWindows"
    exit
}

# Convert the Windows path to WSL path
$bashScriptPathWSL = $bashScriptPathWindows -replace '\\', '/'
$bashScriptPathWSL = '/mnt/' + $bashScriptPathWSL.Substring(0,1).ToLower() + $bashScriptPathWSL.Substring(2)

# Install/update the package (dos2unix) in WSL before executing the script

# Check if dos2unix is installed in WSL
Write-Host "Checking if dos2unix is installed in WSL..."

wsl -d Ubuntu which dos2unix > $null 2>&1
$whichExitCode = $LASTEXITCODE

if ($whichExitCode -ne 0) {
    Write-Host "dos2unix is not installed. Installing dos2unix in WSL..."
    wsl -d Ubuntu sudo apt-get update
    wsl -d Ubuntu sudo apt-get install -y dos2unix
} else {
    Write-Host "dos2unix is already installed in WSL."
}

# Run dos2unix on the bashScriptPathWSL script to fix line endings
Write-Host "Converting line endings of the script using dos2unix..."
wsl -d Ubuntu dos2unix "$bashScriptPathWSL"

# Ensure the script is executable
Write-Host "Setting execute permission on the script..."
wsl -d Ubuntu chmod +x "$bashScriptPathWSL"

# Execute the script in WSL
Write-Host "Executing the script in WSL..."
wsl -d Ubuntu bash "$bashScriptPathWSL"

Write-Host "Script execution completed."
