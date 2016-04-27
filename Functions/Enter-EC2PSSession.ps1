function Enter-EC2PSSession {
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
        if ($Reservation) { $InputObject = $Reservation }
        if ($Instance) { $InputObject = $Instance }


        $InputObject | New-EC2PSSession -PemFile $PemFile -AddressProperty $AddressProperty | Enter-PSSession
    }
}
