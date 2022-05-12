<#
    .SYNOPSIS
        Install winget and install some apps using it

    .DESCRIPTION
        Apps: Keepass, Docker, Telegram, VS Code, Steam, NextCloud client

    .EXAMPLE
        Use
            iex (new-object net.webclient).downloadstring('<URL>')
        to start this script. Place actual URL instead of <URL>.

        URL example:
            https://raw.githubusercontent.com/mrdimfox/scripts/master/win/setup/winget_apps_install.ps1
#>


function Invoke-Main() {
    Write-Host "Finding the latest winget..."

    $LatestMsiInfo = Find-LatestRelease `
        -User microsoft `
        -Repo winget-cli `
        -ArtifactMatch msixbundle

    $LatestMsiUrl = $LatestMsiInfo.browser_download_url

    Write-Host-Success `
        "  Winget version found: $( $LatestReleaseInfo.tag_name )"
    
    Write-Host "Fetching from $LatestMsiUrl..."

    try {
        $wingetBundleFile = New-TempPathToFile -FileName "winget.msixbundle"
        Invoke-WebRequest $LatestMsiUrl.ToString() -OutFile $wingetBundleFile
        Write-Host-Success "  File fetched!"
    
        Write-Host "Installation..."
        Add-AppPackage -path $wingetBundleFile
        Write-Host-Success "  Installation succeeded!"
    }
    catch {
        Write-Error "Script failed!"
        Write-Error $_
        exit(1)
    }
    finally {
        Remove-DirectoryWithFile -FilePath $wingetBundleFile -CheckExistence
    }

    Write-Host "Apps installation started..."

    winget install -h DominikReichl.KeePass
    winget install -h Telegram.TelegramDesktop
    winget install -h Microsoft.VisualStudioCode
    winget install -h Docker.DockerDesktop
    winget install -h Valve.Steam
    winget install -h Nextcloud.NextcloudDesktop
    winget install -h Discord.Discord
    winget install -h qBittorrent.qBittorrent

    Write-Host-Success "`nScript finished successfully!"
}

## -- Helpers
function New-Directory ($Path) {
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Write-Host-Success {
    param (
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor Green
}

function Find-LatestRelease {
    param (
        [string]$User,
        [string]$Repo,
        [string]$ArtifactMatch
    )

    $REPO_URL = "https://api.github.com/repos/$User/$Repo/releases/latest"
    $LatestReleaseInfo = `
        (Invoke-WebRequest -Uri $REPO_URL).Content | ConvertFrom-Json
    $LatestMsiInfo = `
        $LatestReleaseInfo.assets | Where-Object name -Match $ArtifactMatch

    return $LatestMsiInfo
}

function New-TempPathToFile {
    param (
        [string]$FileName
    )

    # Generate temp dir random prefix
    $Prefix = -join ((65..90) + (97..122) `
        | Get-Random -Count 5 `
        | ForEach-Object { [char]$_ })

    $TEMP_FOLDER = (Join-Path $env:APPDATA "$( $Prefix )_Temp")
    $File = Join-Path $TEMP_FOLDER $FileName
    New-Directory -Path $TEMP_FOLDER

    return $File
}

function Remove-DirectoryWithFile {
    param (
        [string]$FilePath,
        [switch]$CheckExistence
    )

    if ($CheckExistence -And $(!(Test-Path -Path $wingetBundleFile -PathType leaf))) {
        return
    }

    $Folder = Split-Path -Path $FilePath -Parent
    Remove-Item -Path $Folder -Recurse
}

## -- Start main routine
Invoke-Main
