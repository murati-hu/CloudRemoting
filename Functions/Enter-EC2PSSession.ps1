<#
.SYNOPSIS
    Opens a PSSession to an Ec2 instance with Administrator credentials
.DESCRIPTION
    The cmdlet accepts pipeline input of EC2 instances and requires a
    private-key file to decrypt and logon with the administrator credentials.

.PARAMETER InstanceId
    Mandatory - EC2 Instance Id for the target machine
.PARAMETER Region
    Mandatory - Region parameter for the EC2 Instance if -InstanceID is
    specified.

.PARAMETER Reservation
    Accepts an EC2 Reservation pipeline input from Get-Ec2Instance output.
.PARAMETER Instance
    Accepts an Amazon EC2 Instance object from the pipeline
.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to decrypt

.EXAMPLE
    Get-Ec2Instance i-2492acfc | Enter-EC2PSSession -PemFile '~/ssh/dev.pem'
.EXAMPLE
    Enter-EC2PSSession -Verbose -InstanceId i-2492acfc -Region us-west-2 -PemFile '~/ssh/dev.pem'

#>
function Enter-EC2PSSession {
    [CmdletBinding(DefaultParameterSetName='ByInstanceId')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string]$InstanceId,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string]$Region,

        [Parameter(Mandatory=$true,ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter(ParameterSetName="ByInstanceId", Mandatory=$true)]
        [Parameter(ParameterSetName="ByInstanceObject", Mandatory=$true)]
        [Parameter(ParameterSetName="ByReservationObject", Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [ValidateSet($null, 'PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty
    )

    Process {
        if ($InstanceId) { $Reservation = Get-EC2Instance -Instance $InstanceId -Region $Region }
        if ($Reservation) { $InputObject = $Reservation }
        if ($Instance) { $InputObject = $Instance }

        $InputObject | New-EC2PSSession -PemFile $PemFile -AddressProperty $AddressProperty | Enter-PSSession
    }
}
