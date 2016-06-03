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

$InstallPath = Manage-EnvVars �CName ChocolateyInstall �CSelect
if($InstallPath -and (Test-Path $InstallPath))
{
    Remove-Item $InstallPath -Recurse -Force
}
Manage-EnvVars �CName ChocolateyInstall �CDelete