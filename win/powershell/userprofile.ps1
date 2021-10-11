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

# -- Oh My Posh config (https://ohmyposh.dev/docs/pwsh)
Import-Module posh-git
Import-Module oh-my-posh
Set-PoshPrompt -Theme amro

# -- Starship config
$env:STARSHIP_CONFIG = "$HOME\.starship"

# -- Scoop config
Import-Module $env:SCOOP\modules\scoop-completion

# -- PSReadline config (https://blog.antosubash.com/posts/setting-up-powershell-with-oh-my-posh-v3)
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionViewStyle InlineView
