##############################################################################
##
## The script is for test database connection
## 
## Author : Edward Guan (edward.guan@mkcorp.com)## Date   : 2016-6-15
## Version: 1.0
##
##############################################################################

# Requires -version 2

param(
    [Parameter(Mandatory = $true)]
    [string]$Config,
    [switch]$EnableLog
)

function Show-StartMessage
{
    $dt = Get-Date -Format "dd MMMM yyyy HH:ss"
    write-host "---------------------------------------------"
    write-host "Execution Info:" -ForegroundColor Green
    write-host "---------------------------------------------"
    write-host "`tStarted at  : " -NoNewline -ForegroundColor Yellow
    write-host "$dt" -ForegroundColor Gray
    write-host "`tRun by      : " -NoNewline -ForegroundColor Yellow
    write-host "$env:USERNAME" -ForegroundColor Gray
    write-host "`tConfig      : " -NoNewline -ForegroundColor Yellow
    write-host $Config -ForegroundColor Gray
    write-host "`tLogfile     : " -NoNewline -ForegroundColor Yellow
    write-host $logfile -ForegroundColor Gray
    write-host "`tCommand     : " -NoNewline -ForegroundColor Yellow
    $cmd = $executionContext.invokeCommand.expandString($($PSCmdlet.MyInvocation.Line))
    write-host $cmd -ForegroundColor Gray
    write-host ""
    if($EnableLog)
    {
@"
---------------------------------------------
Execution Info:
---------------------------------------------
`tStarted at  : $dt
`tRun by      : $env:USERNAME
`tConfig      : $Config
`tLogfile     : $Logfile
`tCommand     : $cmd

"@ | Out-File $logfile -Append
    }
}

function Show-EndMessage($returner)
{
    write-host ""
	write-host "-----------------------"
    write-host "   summary"
    write-host "-----------------------"
    write-host ("Success  : {0}" -f $returner.Success) -ForegroundColor Green
    write-host ("Errors   : {0}" -f $returner.Errors) -ForegroundColor Red
    $errmsgs = $returner.Content | ?{ $_ -match '\[Failed\]' }
    $errmsgs | %{ write-host $_ -ForegroundColor Red }
    if($EnableLog)
    {
@"

-----------------------
   summary
-----------------------
Success  : $($returner.Success)
Errors   : $($returner.Errors)
"@ | Out-File $logfile -Append
$errmsgs | Out-File $logfile -Append
    }
}

try
{
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path

    if($EnableLog)
    {
        $logfolder = "$here\LogFiles"
        New-Item $logfolder -ItemType Directory -Force | Out-Null
        $logfile = Join-Path $logfolder "Test-DBConnection_$(Get-Date -f yyyyMMdd_hhmmss).log"
    }
    Show-StartMessage

    Import-Module "$here\Functions.psm1" -Force -DisableNameChecking

    $configuration = [xml](Get-Content "$here\$Config")
    $configuration.DBConnections.Connection | %{
        write-host $_.Name -ForegroundColor Yellow
        $_.Name | Out-File $logfile -Append

        $servers = Get-Servers $_.Servers
        $returner = Test-SqlConnection -Servers $Servers -DataSource $_.DataSource -Database $_.Database -UserName $_.UserName -Password $_.Password
        write-host ""
        if($EnableLog)
        {
            $returner.Content | Out-File $logfile -Append
            "" | Out-File $logfile -Append
        }
    }
    Show-EndMessage($returner)
}
catch
{
    Write-Host $_ -ForegroundColor Red
    Pause
}

Write-Host ""
Pause