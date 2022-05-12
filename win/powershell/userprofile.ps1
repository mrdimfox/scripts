# -- Conda boilerplate
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
(& "$env:APPDATA\miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | Invoke-Expression
#endregion

# -- Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# -- Oh My Posh config
$POSH_THEME = "$env:POSH_THEMES_PATH\amro.omp.json"
oh-my-posh init pwsh --config $POSH_THEME | Invoke-Expression

# -- Starship config
$env:STARSHIP_CONFIG = "$HOME\.starship"

# -- Scoop config
# enable completion in current shell, use absolute path because PowerShell Core not respect $env:PSModulePath
$SOOP_COMPLETION_MODULE = "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"
if (Test-Path $SOOP_COMPLETION_MODULE) {
    Import-Module $SOOP_COMPLETION_MODULE
}
else {
    Write-Host "scoop-completion not installed."
}

# -- PSReadline config (https://blog.antosubash.com/posts/setting-up-powershell-with-oh-my-posh-v3)
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
# Bash-like view↓
# Set-PSReadLineOption -PredictionViewStyle InlineView

# Coloring some standart utils (like ls)
Import-Module PSColor
