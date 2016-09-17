<#
.SYNOPSIS
    Sets the default EC2 PemFile for this module
.DESCRIPTION
    The cmdlet sets the default EC2 PemFile for all CloudRemoting
    functions, so the user doesn't have to specify it all the time

.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to be used by default

.EXAMPLE
    Set-DefaultEC2PemFile '~/ssh/ec2-dev.pem'
#>
function Set-DefaultEC2PemFile {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$PemFile
    )
    Test-EC2PemFile -PemFile $PemFile -ErrorAction Stop

    Write-Verbose "Setting `$script:DefaultEc2PemFile to $PemFile"
    $script:DefaultEc2PemFile = Resolve-Path $PemFile | Select-Object -ExpandProperty Path
}
