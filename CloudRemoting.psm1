Write-Verbose "CloudRemoting module"

if (Get-Module AWSPowershell -ListAvailable) {
    Import-Module AWSPowershell
} else {
    Write-Warning "AWSPowershell is not found, but some of the cmdlets requires it."
    Write-Warning "Please make sure you have installed it for proper functioning."
}

$functionFilter = Join-Path $PSScriptRoot "Functions\*.ps1"
Get-ChildItem -Path $functionFilter -Recurse | Foreach-Object {
    Write-Verbose "Loading file $($_.Name).."
    . $_.FullName
}
