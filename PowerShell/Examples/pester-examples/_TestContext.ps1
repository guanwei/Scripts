function Fixture {
    param(
        [String]$Name,
        [ScriptBlock]$Action
    )

    Describe $("==={0}===" -f $Name) {
        & $Action
    }
}

function When {
    param(
        [String]$Name,
        [ScriptBlock]$Action,
        [String]$WorkingDirectory
    )
    Before

    Context $("When {0}" -f $Name) {
        if($WorkingDirectory) {
            In $WorkingDirectory {
                & $Action
            }
        } else {
                & $Action
        }
    }
}

function Before{}