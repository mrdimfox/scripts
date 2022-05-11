<#  
    .SYNOPSIS
        This script installs some apps and dev tools using Scoop
    
    .DESCRIPTION
        It installs 7zip, git, miniconda3, llvm (clang), mingw64 (gcc),
        gcc-arm-none-eabi, rust and Windows Build Tools.

    .NOTE
        Use
            iex (new-object net.webclient).downloadstring('<URL>')
        to start this script. Place actual URL instead of <URL>.

        URL example:
            https://github.com/mrdimfox/scripts/blob/master/win/setup/apps_install.ps1
#>
param($InstallArmGccOnlyMagicNumber = 0)

$ACTIVITY_NAME = "Apps installation"
$STEPS_COUNT = 14

$ErrorActionPreference = "Stop"

class Progress {
    [int32]$CurrentStep = 0
    [int32]$StepsCount = 0
    [string]$Activity = ""

    Progress ([string]$Activity, [int32]$StepsCount) {
        $this.Activity = $Activity
        $this.StepsCount = $StepsCount
    }

    NextStep([string]$Status) {
        $percentComplete = (100 / $this.StepsCount) * $this.CurrentStep
        $this.CurrentStep = $this.currentStep + 1
    
        Write-Progress -Activity $this.Activity `
            -Status "$Status" `
            -PercentComplete $percentComplete
        
        Start-Sleep -Milliseconds 100
    }
}

function New-Directory ($Path) {
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Get-YesNoAnswer {
    param (
        [string]$Answer
    )

    $answer = "$Answer [Y/n]"
    $confirmation = Read-Host $answer
    while ($true) {
        if (($confirmation -eq "y") -Or ($confirmation -eq "")) {
            Return $true
        }
        if ($confirmation -eq 'n') {
            Return $false
        }

        $confirmation = Read-Host $answer
    }
}

function Test-App ([string]$Name) {
    Return (Get-Command $Name -errorAction SilentlyContinue)
}

function Install-App {
    param (
        [string]$Name,
        [string]$Cmd,
        [string]$InstallationCmd = "scoop install"
    )
    
    if (!(Test-App -Name $Cmd)) {
        Invoke-Expression -Command (@($InstallationCmd, $Name) -join ' ')
    }
    else {
        Write-Warning -Message `
        ("$Name is already in path! " `
                + "Installation will be skipped.")

        $continue = Get-YesNoAnswer -Answer "Continue installation?"
        if (!($continue)) {
            Write-Host "`n`nScript is finished!" -ForegroundColor Green
            exit
        }
    }
}

# Import add/remove path funcs
$ENV_PATHS_MODULE = "https://gist.githubusercontent.com/mrdimfox/d9df7082fb464289cfc901b94a68a3f2/raw/ee179622d2324ffc1bf1ecdf7b23d1fdb5423ed7/EnvPaths.psm1"
Invoke-Expression -Command (New-Object Net.WebClient).downloadstring($ENV_PATHS_MODULE)

function Install-GccArm {
    Write-Host "Install nodejs."
    Install-App -Name "nodejs" -Cmd "npm"

    Write-Host "Install xpm with npm."
    npm install --global xpm

    Write-Host "Install arm-none-eabi-gcc with xpm."
    xpm install --global @gnu-mcu-eclipse/arm-none-eabi-gcc

    $armGccPath = [io.path]::combine($Env:UserProfile, `
            "AppData", "Roaming", "xPacks", "@gnu-mcu-eclipse", `
            "arm-none-eabi-gcc")

    $armGccVersionFolder = $(Get-ChildItem -Path $armGccPath).Name
    if ([string]::IsNullOrEmpty($armGccVersionFolder)) {
        Write-Error -Message "arm-none-eabi-gcc package is not installed!" `
            "Something gone wrong :("
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }

    $armGccPath = [io.path]::combine($armGccPath, $armGccVersionFolder, `
            ".content", "bin")

    Write-Host "Add $armGccPath to PATH."
    Add-EnvPath -Path $armGccPath -Container 'User'
}

# If script was called only for an installing xpm and arm-none-eabi-gcc
$MAGIC_CONSTANT_ARM_GCC = 2384568923456  # any non zero number
if ($InstallArmGccOnlyMagicNumber -eq $MAGIC_CONSTANT_ARM_GCC) {
    Install-GccArm
    Exit 0
}

$TEMP_DOWNLOAD_FOLDER = (Join-Path $env:APPDATA Temp)
$WIN_BUILD_TOOLS_URL = "https://aka.ms/vs/15/release/vs_buildtools.exe"

$progress = [Progress]::new($ACTIVITY_NAME, $STEPS_COUNT)

$progress.NextStep("Check if Scoop exists")
if (!(Test-App -Name "scoop")) {
    throw "Scoop is not installed! Install it first."
}

# Install 7zip
$progress.NextStep("Install 7zip")
Install-App -Name "7zip" -Cmd "7z"


# Install git
$progress.NextStep("Install git")
Install-App -Name "git" -Cmd "git"
Install-App -Name "git-lfs" -Cmd "git lfs"

# Add additional scoop bucket
$progress.NextStep("Add 'extras', 'nonportable' and 'nirsoft' scoop buckets")
scoop bucket add extras
scoop bucket add nonportable
scoop bucket add nirsoft

# Install git
$progress.NextStep("Install pagent (putty)")
Install-App -Name "putty" -Cmd "plink"
[environment]::setEnvironmentVariable('HOME', $Env:UserProfile, 'User')
[environment]::setEnvironmentVariable('GIT_SSH', (resolve-path (scoop which plink)), 'User')
New-Directory -Path (Join-Path $Env:UserProfile .ssh)

# Install miniconda
$progress.NextStep("Install miniconda")
Install-App -Name "miniconda3" -Cmd "conda"

# Install conda PowerShell extensions
$progress.NextStep("Init conda env")
conda init

# Install LLVM
$progress.NextStep("Install LVM")
Install-App -Name "llvm" -Cmd "clang"

# Install MinGW64
$progress.NextStep("Install MinGW64")
Install-App -Name "gcc" -Cmd "gcc"

# Install Ninja
$progress.NextStep("Install Ninja")
Install-App -Name "ninja" -Cmd "ninja"

# Install CMake
$progress.NextStep("Install CMake")
Install-App -Name "cmake" -Cmd "cmake"

# Install GCC Arm
$progress.NextStep("Install GCC Arm")
Install-App -Name "gcc-arm-none-eabi" -Cmd "arm-none-eabi-gcc"

# Alternative way to install GCC Arm
#Write-Host "GCC Arm needs to be installed from xpm (another package manager) which should be installed from npm."
#$installGccArm = (Get-YesNoAnswer -Answer "Install GCC Arm toolchain now?")
#if ($installGccArm) {
#    # Do a script self elevation and restart it with a MAGIC argument
#    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$MAGIC_CONSTANT_ARM_GCC`"" -Verb RunAs -Wait }
#    else {
#        Install-GccArm
#    }
#}

# Install RustUp
$progress.NextStep("Install RustUp")
Install-App -Name "rustup" -Cmd "rustup"

# Install Windows Build Tools
$progress.NextStep("Install Windows Build Tools")
if ((Get-YesNoAnswer -Answer "Install Windows Build Tools?")) {
    New-Directory -Path $TEMP_DOWNLOAD_FOLDER
    $buildTools = (Join-Path $TEMP_DOWNLOAD_FOLDER "vs_buildtools.exe")
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($WIN_BUILD_TOOLS_URL, $buildTools)

    $buildToolsArgs = @("--passive", "--wait", "--norestart", "--nocache", 
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--includeRecommended")
    Start-Process -Filepath $buildTools -ArgumentList $buildToolsArgs -Verb runas -Wait
    Remove-Item $TEMP_DOWNLOAD_FOLDER -Recurse
}

# Select rust toolchain
$progress.NextStep("Select rust toolchain")
$setMsvcRust = `
(Get-YesNoAnswer -Answer `
        "Change rust toolchain to stable-x86_64-pc-windows-msvc?")
if ($setMsvcRust) {
    rustup default stable-x86_64-pc-windows-msvc
}


Write-Host "`n`nScript work is succesfully finished!" -ForegroundColor Green
exit
