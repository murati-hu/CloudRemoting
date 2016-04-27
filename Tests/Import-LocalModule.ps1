# Load module from the local filesystem, instead from the ModulePath
Remove-Module CloudRemoting -Force -ErrorAction SilentlyContinue
Import-Module (Split-Path $PSScriptRoot -Parent)
