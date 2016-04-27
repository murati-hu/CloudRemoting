<#
.SYNOPSIS
    Opens an RDP session to an Ec2 instance with Administrator credentials
.DESCRIPTION
    The cmdlet accepts pipeline input of EC2 instances and requires a
    private-key file to decrypt and logon with the administrator credentials.

    Th cmdlet uses cmdkey.exe in the background to enable credential passthrough.

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
.PARAMETER AddressProperty
    Optional - String to try to use a specific private or public address

.EXAMPLE
    Get-Ec2Instance i-2492acfc | Enter-EC2RdpSession -PemFile '~/ssh/ec2-dev.pem'
.EXAMPLE
    Enter-EC2RdpSession -InstanceId i-2492acfc -Region us-west-2 -PemFile '~/ssh/ec2-dev.pem'
#>
function Enter-EC2RdpSession {
    [CmdletBinding(DefaultParameterSetName='ByInstanceId')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string]$InstanceId,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string]$Region,

        [Parameter(ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter(Mandatory,ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory,ParameterSetName="ByInstanceObject")]
        [Parameter(Mandatory,ParameterSetName="ByReservationObject")]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [ValidateSet($null, 'PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty='PrivateIpAddress'
    )

    Process {
        if ($InstanceId) { $Reservation = Get-EC2Instance -Instance $InstanceId -Region $Region }
        if ($Reservation) { $Instance = $Reservation.Instances }

        foreach ($i in $Instance) {
            Write-Debug "Fetching credentials for $($i.InstanceId)"
            $credential = $i | Get-EC2Credential -PemFile $PemFile
            if ($credential) {
                foreach ($address in ($i | Get-EC2InstanceAddress -AddressProperty $AddressProperty | Select-Object -Unique)) {
                    if (!$address) { continue }
                    Enter-RdpSession -ComputerName $address -Credential $credential
                }
            } else {
                Write-Debug "Credential cannot be fetched"
            }
        }
    }
}
