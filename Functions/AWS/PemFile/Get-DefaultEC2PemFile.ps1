<#
.SYNOPSIS
    Returns the default EC2 PemFile set for this module
.DESCRIPTION
    The cmdlet returns previously set Default EC2 PemFile
    for this module.

    If it was never set or cleared, the function returns
    $null

.EXAMPLE
    Get-DefaultEC2PemFile
#>
function Get-DefaultEC2PemFile {
    $script:DefaultEc2PemFile
}
