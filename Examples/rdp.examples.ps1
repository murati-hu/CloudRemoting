<#
.SYNOPSIS
    Demo script for opening RDP sessions to AWS EC2 instances

.NOTES
    Please set parameters explicitly, otherwise the demo will
    default to the first random EC2 instance based on your
    AWSPowershell module defaults.
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost","")]
param(
    [string]$InstanceId,
    [string]$Region=$(Get-DefaultAWSRegion | Select-Object -ExpandProperty Region),
    [string]$KeyPath="~/.ssh",
    [string]$PemFile=$(Join-Path $KeyPath "aws_dev_keypair.pem")
)

function Get-RandomEc2InstanceForDemo {
    # If the demo parameters are not set
    # it will try to get a random EC2 instance

    if ([string]::IsNullOrEmpty($instanceId)) {

        $random = Get-EC2Instance | Select-Object -ExpandProperty Instances | Sort-Object LaunchTime -Descending | Select-Object -First 1

        $script:InstanceId=$random.InstanceId
        $script:Region = $random.Placement.AvailabilityZone -replace '\w$',''
        $Script:PemFile = Join-Path $KeyPath "$($random.KeyName).pem"
    }
}

# Import modules
Import-Module AWSPowerShell
Remove-Module CloudRemoting -ErrorAction SilentlyContinue
Import-Module (Split-Path $PSScriptRoot -Parent) # CloudRemoting

Get-RandomEc2InstanceForDemo # If parameters not specifies an exact instance

Write-Host "Using instance $InstanceId @ $Region" -ForegroundColor Cyan
Write-Warning "Please make sure $PemFile keypair is in place."

#region AWS EC2 Instance RDP Session
    Write-Host "Admin EC2 RDP session..." -ForegroundColor Cyan

    Read-Host " by InstanceId and Region - press ENTER to continue..." | Out-Null
    Enter-EC2RdpSession -InstanceId $InstanceId -Region $Region -PemFile $PemFile


    Read-Host " by InstanceObject from pipe press ENTER to continue..." | Out-Null
    $instance = Get-EC2Instance -Instance $InstanceId -Region $Region
    $instance | Enter-EC2RdpSession -PemFile $PemFile
    # or you can use 'ec2rdp' alias

#endregion

#region Custom RDP Session

    Write-Host "Custom RDP session..." -ForegroundColor Cyan
    Read-Host " by Name and custom credential object - press ENTER to continue..." | Out-Null

    $credential = Get-Credential
    Enter-RdpSession -Credential $credential -CleanupCredentials # -Computer

    # Or you can use the 'rdp' alias
    # rdp 'app01.azure.local' -Credential $credential -CleanupCredentials

#endregion
