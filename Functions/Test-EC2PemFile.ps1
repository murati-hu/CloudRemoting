<#
.SYNOPSIS
    Validates the default EC2 pemfile
.DESCRIPTION
    The cmdlet sets the default EC2 PemFile for all CloudRemoting
    functions, so the user doesn't have to specify it all the time

.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to be used by default

.EXAMPLE
    Test-EC2PemFile '~/ssh/ec2-dev.pem'
#>
function Test-EC2PemFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript()]
        [string]$PemFile
    )

    $exists = Test-Path -Path $PemFile
    $nonempty = -Not [string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $PemFile))
    return  $exists -and $nonempty
}
