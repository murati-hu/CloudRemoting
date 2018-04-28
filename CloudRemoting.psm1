Write-Verbose "CloudRemoting module"

if (Get-Module AWSPowershell -ListAvailable) {
    Import-Module AWSPowershell
}
elseif (Get-Module AWSPowerShell.NetCore -ListAvailable) {
    Import-Module AWSPowerShell.NetCore
}
else {
    Write-Warning "AWSPowershell or AWSPowerShell.NetCore is not found, but some of the cmdlets requires it."
    Write-Warning "Please make sure you have installed it for proper functioning."
}

$functionFilter = Join-Path $PSScriptRoot "Functions\*.ps1"
Get-ChildItem -Path $functionFilter -Recurse | Foreach-Object {
    Write-Verbose "Loading file $($_.Name).."
    . $_.FullName
}
