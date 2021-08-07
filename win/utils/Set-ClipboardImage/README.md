## Convert to script to .exe

Install ps2exe (sudo required):

```ps
Install-Module -Force ps2exe
```

Convert:

```ps
Invoke-ps2exe .\Set-ClipboardImage.ps1 .\Set-ClipboardImage.exe
```