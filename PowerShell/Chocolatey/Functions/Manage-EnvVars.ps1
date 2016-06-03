function Manage-EnvVars
{
    Param(
        [parameter(Mandatory=$true)]
        [String] $Name,
        [String] $Value,
        [ValidateSet("Machine", "User", "Process")]
        [String] $Scope,
        [Switch] $Select,
        [Switch] $Delete
    )

    if($Select)
    {
       [Environment]::GetEnvironmentVariable($Name)
    }
    elseif($Delete)
    {
       [Environment]::SetEnvironmentVariable($Name, $null, "Machine")
       [Environment]::SetEnvironmentVariable($Name, $null, "Process")
       [Environment]::SetEnvironmentVariable($Name, $null, "User")

       if (Test-Path env:$Name)
       {
           Remove-Item -Path Env:$Name -ErrorAction -SilentlyContinue | Out-Null
       }
   }
   else
   {
       if(-not $Scope) {$Scope="Machine"}
       if(-not $Value) {$Value="No value given!!!"}
       [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
       New-Item -path Env: -Name $Name -Value $Value –Force -ErrorAction SilentlyContinue | Out-Null
    }
}
