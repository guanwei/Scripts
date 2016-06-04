. "$(Join-Path $PSScriptRoot _TestContext.ps1)"

$module = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.ps1",".psm1")
$code = Get-Content $module | Out-String
Invoke-Expression $code

Describe "Invoke-NUnit" {
    Mock Get-NUnitPackage {return @{Exe='nunit-console.exe'}}
    Mock Invoke-Executable {}

    It "should use labels switch" {
        Invoke-NUnit
        Assert-MockCalled Invoke-Executable -Exactly 1 {$Parameters[0] -eq '/labels'}
    }
}