. (Join-Path $PSScriptRoot '../TestCommon.ps1')

Describe "Set-DefaultEC2PemFile" {
    $emptyFile = Join-Path $PSScriptRoot '../PemFile/empty.txt'
    $notEmptyFile = Resolve-Path (Join-Path $PSScriptRoot '../PemFile/notempty.txt') | Select-Object -ExpandProperty Path

    Context "Valid input" {
        it "should not throw if valid file passed" {        
            { Set-DefaultEC2PemFile -PemFile $notEmptyFile } |
            Should Not Throw
        }

        it "should set the default PemFile" {
            Get-DefaultEC2PemFile | Should Be $notEmptyFile
        }
    }

    Context "Invalid input" {
        foreach($case in @($null, '', 'x:\unlikelytoexists',$emptyFile)) {
            it "should throw exception if '$case' passed" {
                { Set-DefaultEC2PemFile -PemFile $case } | Should Throw
            }

            it "should NOT change the default PemFile" {
                Get-DefaultEC2PemFile | Should Be $notEmptyFile
            }
        }
    }
}
