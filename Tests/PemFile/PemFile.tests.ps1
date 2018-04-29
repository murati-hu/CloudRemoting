. (Join-Path $PSScriptRoot '../TestCommon.ps1')

Describe "Validation - No Default EC2 PemFile" {
    $fakeInstance = 'i-123456'
    $fakeRegion = 'us-east-1'
    $emptyFile = Resolve-Path(Join-Path $PSScriptRoot '../PemFile/empty.txt')

    function Test-PemFileValidation([string]$FunctionName) {
        Context $FunctionName {
            it "should throw error if not specified" {
                $test = { . $FunctionName -InstanceId $fakeInstance -Region $fakeRegion }
                $test | Should Throw $exceptionText
            }

            $exceptionText = 'Provide an argument that is not null or empty'
            foreach($case in @($null, '')) {
                it "should throw '$exceptionText' if '$case' passed" {
                    $test = { . $FunctionName -InstanceId $fakeInstance -Region $fakeRegion -PemFile $case }
                    $test | Should Throw $exceptionText
                }
            }

            $exceptionText = 'Please provide the path to a valid PemFile.'
            foreach($case in @('x:\unlikelytoexists',$emptyFile)) {
                it "should throw '$exceptionText' if '$case' passed" {
                    $test = { . $FunctionName -InstanceId $fakeInstance -Region $fakeRegion -PemFile $case }
                    $test | Should Throw $exceptionText
                }
            }
        }
    }

    Clear-DefaultEC2PemFile
    @(
        'Get-Ec2Credential'
        'New-EC2PSSession'
        'Enter-EC2PSSession'
        'Enter-EC2RDPSession'
    ) | ForEach-Object {
        Test-PemFileValidation -FunctionName $_
    }
}
