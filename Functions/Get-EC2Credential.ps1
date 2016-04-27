<#
.SYNOPSIS
    Returns Administrator credentials for an EC2 Instance
.DESCRIPTION
    The cmdlet accepts pipeline input of EC2 instances and requires a
    private-key file to decrypt and logon with the administrator credentials.

.PARAMETER InstanceObject
    Accepts an EC2 Reservation pipeline input from Get-Ec2Instance output.
.PARAMETER InstanceId
    Accepts an Amazon EC2 Instance object from the pipeline
.PARAMETER Region
    Mandatory - AWS Region if InstanceId is specified instead of InstanceObject
.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to decrypt

.EXAMPLE
    Get-EC2Credential -InstanceId i-d56ef3 -PemFile '~/ssh/ec2-dev.pem' -Region us-west-2
.EXAMPLE
    Get-ECInstance -InstanceId i-d56ef3 | Get-EC2Credential -PemFile '~/ssh/ec2-dev.pem'
#>
function Get-EC2Credential {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance]$InstanceObject,

        [Parameter(Mandatory, ParameterSetName="ByInstanceId")]
        [string]$InstanceId,

        [Parameter(Mandatory, ParameterSetName="ByInstanceId")]
        [string]$Region,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [switch]$AsText
    )

    Write-Debug "ParameterSet: $($PsCmdlet.ParameterSetName)"

    if ($InstanceObject) {
        $InstanceId = $InstanceObject.InstanceId
        $Region = $InstanceObject.Placement.AvailabilityZone -replace '\w$',''
    }

    $rawPassword = Get-EC2PasswordData -Region $Region -InstanceId $InstanceId -Decrypt -PemFile $PemFile
    if ($AsText) { return $rawPassword }

    if ($rawPassword) {
        $securePassword = ConvertTo-SecureString $rawPassword -AsPlainText -Force
        New-Object System.Management.Automation.PSCredential('~\Administrator',$securePassword)
    }
}
