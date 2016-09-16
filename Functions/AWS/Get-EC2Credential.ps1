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
    [CmdletBinding(DefaultParameterSetName='ByInstanceId')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText","")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="ByInstanceId")]
        [string]$InstanceId,

        [Parameter(Mandatory=$true, ParameterSetName="ByInstanceId")]
        [string]$Region,

        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance]$InstanceObject,

        [Parameter(Mandatory=$true,ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PemFile=$script:DefaultEc2PemFile,

        [Parameter()]
        [switch]$AsText
    )

    Write-Verbose "ParameterSet: $($PsCmdlet.ParameterSetName)"

    Test-EC2PemFile -PemFile $PemFile -ErrorAction Stop
    $PemFile = Resolve-Path $PemFile

    if ($Reservation) { $InstanceObject = $Reservation.Instances | Select-Object -First 1 }

    if ($InstanceObject) {
        $InstanceId = $InstanceObject.InstanceId
        $Region = $InstanceObject.Placement.AvailabilityZone -replace '\w$',''
        Write-Verbose "Required Private-key: $($InstanceObject.KeyName)"
    }

    Write-Verbose "Fetching Credentials for $InstanceId@$Region"
    Write-Verbose "Keyfile used: $PemFile"
    $rawPassword = Get-EC2PasswordData -Region $Region -InstanceId $InstanceId -Decrypt -PemFile $PemFile
    if ($AsText) { return $rawPassword }

    if ($rawPassword) {
        $securePassword = ConvertTo-SecureString $rawPassword -AsPlainText -Force
        New-Object System.Management.Automation.PSCredential('~\Administrator',$securePassword)
    }
}
