Open PowerShell as Admin
Run Set-ExecutionPolicy RemoteSigned


# Install Git
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements

# Install WebStorm
winget install -e --id JetBrains.WebStorm --accept-package-agreements --accept-source-agreements

# (Optional) Install PuTTY
# winget install -e --id PuTTY.PuTTY --accept-package-agreements --accept-source-agreements

# Install Obsidian
winget install -e --id Obsidian.Obsidian --accept-package-agreements --accept-source-agreements

# Install ShareX
winget install -e --id ShareX.ShareX --accept-package-agreements --accept-source-agreements

# (Optional) Install Visual Studio Code
# winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements

# Install Yarn
winget install -e --id Yarn.Yarn --accept-package-agreements --accept-source-agreements

# Install Slack
winget install -e --id SlackTechnologies.Slack --accept-package-agreements --accept-source-agreements

# Install NVM for Windows
winget install -e --id CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements

# Install DataGrip
winget install -e --id JetBrains.DataGrip --accept-package-agreements --accept-source-agreements

# Install Firefox
winget install -e --id Mozilla.Firefox --accept-package-agreements --accept-source-agreements

# Install Neovim
winget install -e --id Neovim.Neovim --accept-package-agreements --accept-source-agreements

# Install Node
winget install -e --id OpenJS.NodeJS --accept-package-agreements --accept-source-agreements



npm install -g @angular/cli