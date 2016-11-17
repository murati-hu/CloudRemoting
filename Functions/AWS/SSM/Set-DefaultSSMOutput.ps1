<#
.SYNOPSIS
    Sets the default SSM Output S3 bucket and prefix
.DESCRIPTION
    The cmdlet sets the default S3 bucket and prefix for
    capturing SSM outputs.

.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to be used by default

.EXAMPLE
    Set-DefaultSSMOutput
#>
function Set-DefaultSSMOutput {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$BucketName,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPrefix
    )

    $Script:DefaultSSMOutputS3BucketName=$BucketName
    $Script:DefaultSSMOutputS3KeyPrefix=$KeyPrefix
}
