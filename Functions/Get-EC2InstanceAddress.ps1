function Get-EC2InstanceAddress {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance]$InstanceObject,

        [ValidateSet('PrivateIpAddress','PublicIpAddress','PrivateDnsName','PublicDnsName')]
        [string]$AddressProperty
    )
    if ($InstanceObject) {
        if ($AddressProperty) {
            Write-Verbose "Address filtering for '$AddressProperty'"
            $InstanceObject.$AddressProperty
        } else {
            Write-Verbose "Returning unfiltered addresses"
            $InstanceObject.PrivateIpAddress
            $InstanceObject.PublicIpAddress
            $InstanceObject.PrivateDnsName
            $InstanceObject.PublicDnsName
            $InstanceObject.Tags | Where Key -eq ComputerName | Select-Object -ExpandProperty Value
        }
    }
}
