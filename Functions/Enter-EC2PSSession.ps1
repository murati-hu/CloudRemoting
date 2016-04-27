<#
.SYNOPSIS
    Opens a PSSession to an Ec2 instance with Administrator credentials
.DESCRIPTION
    The cmdlet accepts pipeline input of EC2 instances and requires a
    private-key file to decrypt and logon with the administrator credentials.

.PARAMETER Reservation
    Accepts an EC2 Reservation pipeline input from Get-Ec2Instance output.
.PARAMETER Instance
    Accepts an Amazon EC2 Instance object from the pipeline
.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to decrypt

.EXAMPLE
    Get-Ec2Instance i-ade67df | Enter-EC2PSSession -PemFile '~/ssh/ec2-dev.pem'
#>
function Enter-EC2PSSession {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter(ParameterSetName="ByInstanceObject", Mandatory=$true)]
        [Parameter(ParameterSetName="ByReservationObject", Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [ValidateSet('PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty
    )

    Process {
        if ($Reservation) { $InputObject = $Reservation }
        if ($Instance) { $InputObject = $Instance }

        $InputObject | New-EC2PSSession -PemFile $PemFile -AddressProperty $AddressProperty | Enter-PSSession
    }
}
