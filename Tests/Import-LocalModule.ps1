# Load module from the local filesystem, instead from the ModulePath
Remove-Module EC2Remoting -Force -ErrorAction SilentlyContinue
Import-Module (Split-Path $PSScriptRoot -Parent)

$script:FunctionPath = Resolve-Path (Join-Path $PSScriptRoot '../Functions')
$script:FixturePath = Resolve-Path (Join-Path $PSScriptRoot 'Fixtures')
