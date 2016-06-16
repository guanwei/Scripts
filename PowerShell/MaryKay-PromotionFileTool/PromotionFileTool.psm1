function Write-Log
{
    [cmdletbinding()]
    Param(
        [Parameter(ValueFromPipeline=$true)]
        [string] $Message,
        [ValidateSet('Error','Warning','Info')]
        [string] $Level = "Info",
        [Parameter()] 
        [ValidateSet('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')]
        [Alias("Fore")]
        [string] $ForegroundColor = ($host.UI.RawUI.ForegroundColor),
        [IO.FileInfo] $Path = "$env:temp\PowerShellLog.txt",
        [Switch] $Clobber
    ) 
     
    Begin {}
     
    Process 
    {
        try
        {                  
            switch ($Level)
            {
                'Error' { Write-Error $Message }
                'Warning' { Write-Warning $Message }
                'Info' { Write-Host $Message -ForegroundColor $ForegroundColor }
            }
     
            if ($Clobber) 
            {
                $Message | Out-File -FilePath $Path
            } 
            else 
            {
                $Message | Out-File -FilePath $Path -Append
            }
        }
        catch
        {
            throw "Failed to create log entry in: '$Path'. The error was: '$_'."
        }
    }
     
    End {}
}