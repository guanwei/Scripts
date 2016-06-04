$imports = @(
    $(Join-Path $PSScriptRoot _TestContext.ps1),
    $PSCommandPath -replace ".Tests.","."
)

foreach($import in $imports) {
    . "$import"
}

Describe "Add" {
    Context "when the input is an empty string" {
        $input = " "
        $expected = 0
        $actual = Add $input

        It "should return zero" {
            $actual | Should Be $expected
        }
    }

    Context "when the input is just one number" {
        $input = "1"
        $expected = 1
        $actual = Add $input

        It "should return the number" {
            $actual | Should Be $expected
        }
    }

    Context "when adding 1 and 2" {
        $actual = Add "1,2"

        It "should sum them" {
            $actual | Should Be 3
        }
    }
}

Fixture "Verify-Result" {
    When "the result file exist" {
        Setup -File ".\result.txt"

        It "should not display an error" {
            Verify-Result -ea:SilentlyContinue -ev actual
            $actual | Should BeNullOrEmpty
        }
    } -WorkingDirectory $TestDrive
}