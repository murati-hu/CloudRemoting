<#
.SYNOPSIS
    Clears the default EC2 PemFile for this module
.DESCRIPTION
    The cmdlet clears a previously set Default EC2 PemFile
    for this module cmdlets

.EXAMPLE
    Clear-DefaultEC2PemFile
#>
function Clear-DefaultEC2PemFile {
    Write-Verbose "Clearing `$script:DefaultEc2PemFile"
    $script:DefaultEc2PemFile = $null
}
