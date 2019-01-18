<#  
    .SYNOPSIS
        This script installs some apps and dev tools using Scoop
    
    .DESCRIPTION
        It installs 7zip, git, miniconda3, llvm (clang), mingw64 (gcc),
        gcc-arm-none-eabi, rust and Windows Build Tools.

    .NOTE
        Use
            iex (new-object net.webclient).downloadstring('https://waa.ai/ol6t')
        to start this.
#>

$ACTIVITY_NAME = "Apps installation"
$STEPS_COUNT = 13

$ErrorActionPreference = "Stop"

class Progress
{
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
        [string]$Cmd
    )
    
    if (!(Test-App -Name $Cmd)) {
        scoop install $Name
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

$TEMP_DOWNLOAD_FOLDER = (Join-Path $env:APPDATA Temp)
$WIN_BUILD_TOOLS_URL = "https://aka.ms/vs/15/release/vs_buildtools.exe"

$progress = [Progress]::new($ACTIVITY_NAME, $STEPS_COUNT)

$progress.NextStep("Check if Scoop exists")
if (!(Test-App -Name "scoop"))
{
    throw "Scoop is not installed! Install it first."
}

# Install 7zip
$progress.NextStep("Install 7zip")
Install-App -Name "7zip" -Cmd "7z"

# Install git
$progress.NextStep("Install git with openssh")
Install-App -Name "git-with-openssh" -Cmd "git"
[environment]::setEnvironmentVariable('HOME', $Env:UserProfile, 'User')
New-Directory -Path (Join-Path $Env:UserProfile .ssh)

# Add 'extras' scoop bucket
$progress.NextStep("Add 'extras' scoop bucket")
scoop bucket add extras

# Install miniconda
$progress.NextStep("Install miniconda")
Install-App -Name "miniconda3" -Cmd "conda"

# Install conda PowerShell extensions
$progress.NextStep("Install conda PowerShell extensions")
$condaPath = [io.path]::combine($env:SCOOP, "apps", "miniconda3", "current")
$condaActivateBat = [io.path]::combine($condaPath, "Scripts", "activate.bat")
$condaActivatePs1 = [io.path]::combine($condaPath, "Scripts", "activate.ps1")

if (!(Test-Path -Path $condaActivatePs1)) {
    Start-Process 'cmd' -ArgumentList `
        ("/K $condaActivateBat $condaPath && " `
        + "conda install -y -n root -c pscondaenvs pscondaenvs && " `
        + "exit") -Wait

    &$condaActivatePs1 base
}
else {
    activate base
}

# Install Python linter and formater
$progress.NextStep("Install Python linter and formater")
conda install --quiet -y yapf flake8
deactivate

# Install LLVM
$progress.NextStep("Install LVM")
Install-App -Name "llvm" -Cmd "clang"

# Install MinGW64
$progress.NextStep("Install MinGW64")
Install-App -Name "gcc" -Cmd "gcc"

# Install GCC Arm
$progress.NextStep("Install GCC Arm")
Install-App -Name "gcc-arm-none-eabi" -Cmd "arm-none-eabi-gcc"

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