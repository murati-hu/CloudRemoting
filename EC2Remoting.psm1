Write-Verbose "EC2Remoting module"

$functionFilter = Join-Path $PSScriptRoot "Functions\*.ps1"
Get-ChildItem -Path $functionFilter -Recurse | Foreach-Object {
    Write-Verbose "Loading file $($_.Name).."
    . $_.FullName
}
