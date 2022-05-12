Install-PackageProvider -Name NuGet -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name PSReadLine -AllowPrerelease
Install-Module PSColor

winget install oh-my-posh
