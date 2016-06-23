$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if(Test-Path "$here/Functions/Manage-EnvVars.ps1")
{
    & "$here/Functions/Manage-EnvVars.ps1"
}
else
{
    Write-Host "Can not found `"$here/Functions/Manage-EnvVars.ps1`"" -ForegroundColor Red
    exit 1
}

Manage-EnvVars -Name ChocolateyInstall -Value D:\chocolatey
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
