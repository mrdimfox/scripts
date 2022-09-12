Install-PackageProvider -Name NuGet -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name PSReadLine -AllowPrerelease
Install-Module PSColor

winget install JanDeDobbeleer.OhMyPosh -s winget
