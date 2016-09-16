. (Join-Path $PSScriptRoot '../TestCommon.ps1')

Describe "Test-EC2PemFile validation" {
    $emptyFile = Join-Path $PSScriptRoot '../PemFile/empty.txt'
    $notEmptyFile = Join-Path $PSScriptRoot '../PemFile/notempty.txt'

    it "should return false if not specified" {
        Test-EC2PemFile -ErrorAction SilentlyContinue | Should Be $false
    }
    it "should return false on invalid files" {
        Test-EC2PemFile -PemFile $null -ErrorAction 0 | Should Be $false
        Test-EC2PemFile -PemFile '' -ErrorAction 0 | Should Be $false
        Test-EC2PemFile -PemFile 'x:\unlikelytoexist' -ErrorAction 0 | Should Be $false
        Test-EC2PemFile -PemFile $emptyFile -ErrorAction 0 | Should Be $false
    }

    it "should return true on valid file" {
        Test-EC2PemFile -PemFile $notEmptyFile | Should Be $true
    }
}
