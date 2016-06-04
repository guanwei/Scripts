function Add($in) {
    if($in) {
        $numbers = $in -split ','
        if($numbers.length -eq 1) {
            return $numbers[0]
        }
        return [int]$numbers[0] + [int]$numbers[1]
    }

    return 0
}

function Verify-Result {
    [CmdletBinding()]
    param()
    if((Test-Path .\result.txt -PathType:Leaf) -eq $false) {
        Write-Error "missing result file"
    }
}