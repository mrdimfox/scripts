<#  
    .SYNOPSIS
        This script installs Scoop package manage into %appdata%/scoop dir

    .DESCRIPTION
        For a proper script work you should enable a Developer mode on you PC.
        After this script is started it creates folder "scoop" in %appdata%
        directory. Scoop itself and local programs will be installed into
        "local" subdir. If you want to change a global path for Scoop script
        will ask you about an admin's rights. Global path will se set as 
        "C:/ScoopGlobal".

    .NOTES
        Use
            iex (new-object net.webclient).downloadstring('<URL>')
        to start this script. Place actual URL instead of <URL>.

        URL example:
            https://raw.githubusercontent.com/mrdimfox/scripts/master/win/setup/scoop_setup.ps1
#>

param($SetGlobalOnlyMagicNumber=0)

$ACTIVITY_NAME = "Scoop installation"
$STEPS_COUNT = 7

$ErrorActionPreference = "Stop"

function New-Directory ($Path) {
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path    
    }
}

function Test-DeveloperMode {
    if (!(Get-WindowsDeveloperLicense).IsValid) {
        throw `
            'You should enable Developer mode to ' `
            + 'make symbolic links without ' `
            + 'admin privileges!' `
            + 'see more: https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development'
    }
}

function New-SymbolicLink {
    Param
    (
        [string]$From,
        [string]$To
    )

    # It just does not work without admin rights even
    # if Developer mode is enabled
    #  New-Item -Path $To -ItemType SymbolicLink -Value $From

    $command = "cmd /c mklink /d"
    Invoke-Expression -Command "$command ""$To"" ""$From"""
}

function Get-YesNoAnswer {
    param (
        [string]$Answer
    )

    $answer = "$Answer [y/n]"
    $confirmation = Read-Host $answer
    while ($true) {
        if ($confirmation -eq "y") {
            Return $true
        }
        if ($confirmation -eq 'n') {
            Return $false
        }

        $confirmation = Read-Host $answer
    }
}

class Progress {
    [int32]$CurrentStep = 0
    [int32]$StepsCount = 0
    [string]$Activity = ""

    Progress ([string]$Activity, [int32]$StepsCount) {
        $this.Activity = $Activity
        $this.StepsCount = $StepsCount
    }

    NextStep([string]$Status){
        $percentComplete = (100 / $this.StepsCount) * $this.CurrentStep
        $this.CurrentStep = $this.currentStep + 1
    
        Write-Progress -Activity $this.Activity `
                       -Status "$Status" `
                       -PercentComplete $percentComplete
        
        Start-Sleep -Milliseconds 100
    }
}

$progress = [Progress]::new($ACTIVITY_NAME, $STEPS_COUNT)

$programDataSymbolicPath = (Join-Path $Env:UserProfile ".opt")
$programDataAbsPath = $env:APPDATA
$globalScoopAbsPath = (Join-Path $env:SystemDrive "ScoopGlobal")

$localScoopFolderPath = `
    ([io.path]::combine($programDataSymbolicPath, "scoop", "local"))
$globalScoopFolderPath = `
    ([io.path]::combine($programDataSymbolicPath, "scoop", "global"))


# If script was called only for a global scoop path setup
$MAGIC_CONSTANT = 48576839746  # any non zero number
if ($SetGlobalOnlyMagicNumber -eq $MAGIC_CONSTANT) {
    Write-Host "Set soop global installation path to a $globalScoopAbsPath."

    [environment]::setEnvironmentVariable('SCOOP_GLOBAL', $globalScoopAbsPath, 'Machine')
    $env:SCOOP_GLOBAL = $globalScoopAbsPath

    New-Directory -Path $globalScoopAbsPath
    if (!(Test-Path -Path $globalScoopFolderPath)) {
        New-SymbolicLink -From $globalScoopAbsPath -To $globalScoopFolderPath
    }

    Write-Host "Script work is succesfully finished!"
    Write-Host "Global installation folder is $env:SCOOP_GLOBAL"

    Exit 0
}

# Check PowerShell version
$progress.NextStep("Check PowerShell version")
$psVer = $psVersionTable.psVersion
if ($psVer.Major -lt 3) {
    throw `
        "Scoop only works with Powershell 3 " `
        + "and move newer versions. You have " `
        + "$psVer."
}

# Check if Scoop already exists
$progress.NextStep("Check if Scoop already exists")
if (Get-Command "scoop" -errorAction SilentlyContinue)
{
    throw "Scoop is already installed. Remove it first."
}

# Create a symlink '.opt' linked to %APPDATA% inside a user folder
$progress.NextStep("Create a symlink '.opt' linked to %APPDATA% inside a user folder")
if (!(Test-Path -Path $programDataSymbolicPath)) {
    if (!(Test-Path -Path $programDataAbsPath)) {
        New-Directory $programDataAbsPath
        Write-Host "Directory $programDataAbsPath was created."
    }

    Test-DeveloperMode

    New-SymbolicLink -From $programDataAbsPath -To $programDataSymbolicPath
    Write-Host `
        "$programDataSymbolicPath -> $programDataSymbolicPath " `
        + "symlink was created."
}

# Set policy stuff
$progress.NextStep("Set policy stuff")
Write-Host "Set policy 'RemoteSigned'"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Set Scoop location for user applications
$progress.NextStep("Set Scoop location for user applications")
Write-Host "Set soop local installation path to a $localScoopFolderPath."
[environment]::setEnvironmentVariable('SCOOP', $localScoopFolderPath, 'User')
$env:SCOOP = $localScoopFolderPath

# Install Scoop
$progress.NextStep("Install Scoop")
Write-Host "Start scoop installation..."
Invoke-Expression -Command `
    (New-Object Net.WebClient).downloadstring('https://get.scoop.sh')
Write-Host "Scoop installation is finished."

# Setup a global install path for scoop
$progress.NextStep("Setup a global install path for scoop")
$initGlobal = (Get-YesNoAnswer -Answer "Setup a global setup path now?")
if ($initGlobal) {
    $env:SCOOP_GLOBAL = $globalScoopAbsPath
    # Do a script self elevation and restart it with a MAGIC argument
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$MAGIC_CONSTANT`"" -Verb RunAs -Wait}
    else {
        [environment]::setEnvironmentVariable( `
            'SCOOP_GLOBAL', $globalScoopFolderPath, 'Machine')
    }
}

# Print final message
$progress.NextStep("Finish")
$finalMsg = `
    "`nScript work is succesfully finished.`n"`
    + "Scoop was installed to a folder:`n"`
    + "    $env:SCOOP"

if ($initGlobal) {
    $finalMsg `
        = "$finalMsg`nGlobal installation folder is`n"`
        + "    $env:SCOOP_GLOBAL"
}

Write-Host $finalMsg -ForegroundColor Green
