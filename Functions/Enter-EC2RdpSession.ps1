<#
.SYNOPSIS
    Opens an RDP session to an Ec2 instance with Administrator credentials
.DESCRIPTION
    The cmdlet accepts pipeline input of EC2 instances and requires a
    private-key file to decrypt and logon with the administrator credentials.

    Th cmdlet uses cmdkey.exe in the background to enable credential passthrough.

.PARAMETER Reservation
    Accepts an EC2 Reservation pipeline input from Get-Ec2Instance output.
.PARAMETER Instance
    Accepts an Amazon EC2 Instance object from the pipeline
.PARAMETER PemFile
    Mandatory - Path to the PrivateKey file to decrypt
.PARAMETER AddressProperty
    Optional - String to try to use a specific private or public address
.EXAMPLE
    Get-Ec2Instance i-ade67df | Enter-EC2RdpSession -PemFile '~/ssh/ec2-dev.pem'
#>
function Enter-EC2RdpSession {
    [cmdletbinding()]
    param(
        [Parameter(ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter(Mandatory,ParameterSetName="ByInstanceObject")]
        [Parameter(Mandatory,ParameterSetName="ByReservationObject")]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [Parameter(ParameterSetName="ByInstanceObject")]
        [Parameter(ParameterSetName="ByReservationObject")]
        [ValidateSet('PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty='PrivateIpAddress'
    )

    Process {
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
