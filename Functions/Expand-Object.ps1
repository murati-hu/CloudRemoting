<#
.SYNOPSIS
    Enriches the inputobject, by expanding properties to the top
    level.
.DESCRIPTION
    Expands the InputObject with the -ExpandProperty and merges its
    content to the top level.

.PARAMETER InputObject
    Mandatory - InputObject to be expanded
.PARAMETER Force
    Optional - Switch to to override properties that already exist

.EXAMPLE
    Invoke-SSMCommand { Get-Date } -EnableCliXml | Expand-Object -Force
#>
function Expand-Object {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PsObject[]]$InputObject,

        [Parameter()]
        [Alias('Property')]
        [string[]]$ExpandProperty=@('Tags','SSMCommandInputObject'),

        [Parameter()]
        [switch]$Force
    )

    process {
        $InputObject |
        ForEach-Object {
            foreach ($expandable in ($_| Get-Member -Name $ExpandProperty | Select-Object -ExpandProperty Name)) {
                Write-Verbose "Processing '$expandable'.."
                if ($_.$expandable | Get-Member -Name @('Key','Value') -ErrorAction SilentlyContinue) {
                    Write-Verbose "Hash expansion"
                    foreach($enty in $_.$expandable) {
                        $_ | Add-Member -NotePropertyName $enty.Key -NotePropertyValue $enty.Value -Force:$Force
                    }
                }
                elseif ($_.$expandable) {
                    Write-Verbose "PSObject expansion"
                    foreach($property in ($_.$expandable | Get-Member -MemberType Properties)) {
                        $_ | Add-Member -NotePropertyName $property.Name -NotePropertyValue $_.$expandable.($Property.Name) -Force:$Force
                    }
                }

                $_
            }
        }
    }
}
