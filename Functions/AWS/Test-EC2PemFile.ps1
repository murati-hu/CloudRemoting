<#
.SYNOPSIS
    Validates the default EC2 pemfile
.DESCRIPTION
    This cmdlet is used for a vague validation of the PemFile
.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to be used by default

.EXAMPLE
    Test-EC2PemFile '~/ssh/ec2-dev.pem'
#>
function Test-EC2PemFile {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$PemFile
    )

    $exists = Test-Path -Path $PemFile
    $nonempty = -Not [string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $PemFile))
    return $exists -and $nonempty
}
