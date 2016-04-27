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
function New-EC2PSSession {
    [cmdletbinding()]
    param(
        [Parameter(ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        #TODO: validate not null
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter(ParameterSetName="ByInstanceObject")]
        [Parameter(ParameterSetName="ByReservationObject")]
        [ValidateScript({Test-Path -Path $_ })]
        [string]$PemFile,

        [ValidateSet('PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty
    )

    Process {
        if ($Reservation) { $Instance = $Reservation.Instances }

        foreach ($i in $Instance) {
            Write-Debug "Fetching credentials for $($i.InstanceId)"
            $credential = $i | Get-EC2Credential -PemFile $PemFile
            if ($credential) {
                foreach ($address in ($i | Get-EC2InstanceAddress -AddressProperty $AddressProperty | Select-Object -Unique)) {
                    if (!$address) { continue }
                    try {
                        Write-Debug "Trying to connect to address '$address'.."
                        $session = $null
                        $session = New-PSSession -ComputerName $address -Credential $credential
                        if ($session) {
                            Write-Debug "Session established on '$address'.."
                            return $session
                        }
                    } catch {
                        Write-Error $_
                    }
                }
            } else {
                Write-Debug "Credential cannot be fetched"
            }
        }
    }
}
