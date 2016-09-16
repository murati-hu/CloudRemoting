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
        [Parameter(Position=0)]
        [string]$PemFile
    )

    try {
        Write-Verbose "Testing $PemFile path.."
        if (-Not (Test-Path -Path $PemFile -ErrorAction Stop)) { throw }

        Write-Verbose "Testing if content is not empty.."
        $content = Get-Content -Raw -Path $PemFile -ErrorAction Stop
        if([string]::IsNullOrWhiteSpace($content)) { throw }

        return $true
    } catch {
        Write-Error "Please provide the path to a valid PemFile."
    }
    return $false
}
