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
.PARAMETER AddressProperty
    Optional - String to try to use a specific private or public address

.EXAMPLE
    New-EC2PSSession -Verbose -InstanceId i-2492acfc -Region us-west-2 -PemFile '~/ssh/dev.pem'
.EXAMPLE
    Get-Ec2Instance i-ade67df | New-EC2PSSession -PemFile '~/ssh/dev.pem'
#>
function New-EC2PSSession {
    [CmdletBinding(DefaultParameterSetName='ByInstanceId')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","")]
    param(
        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string[]]$InstanceId,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string]$Region,

        [Parameter(Mandatory=$true,ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PemFile=$script:DefaultEc2PemFile,

        [Parameter()]
        [ValidateSet($null, 'PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty

        #Authentication Mechanism
        #[System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication
    )

    Begin { Test-EC2PemFile -PemFile $PemFile -ErrorAction Stop }

    Process {
        if ($InstanceId) {
            $Reservation = Get-EC2Instance -Instance $InstanceId -Region $Region
        }

        if ($Reservation) { $Instance = $Reservation.Instances }

        foreach ($i in $Instance) {
            Write-Verbose "Fetching credentials for $($i.InstanceId)"
            $credential = $i | Get-EC2Credential -PemFile $PemFile
            if ($credential) {
                foreach ($address in ($i | Get-EC2InstanceAddress -AddressProperty $AddressProperty | Select-Object -Unique)) {
                    if (!$address) { continue }
                    try {
                        Write-Verbose "Trying to connect to address '$address'.."
                        $session = $null
                        $session = New-PSSession -ComputerName $address -Credential $credential
                        if ($session) {
                            Write-Verbose "Session established on '$address'.."
                            return $session
                        }
                    } catch {
                        Write-Error $_
                    }
                }
            } else {
                Write-Warning "Credential cannot be fetched. Make sure you pass valid key for '$($i.KeyName)'"
            }
        }
    }
}
