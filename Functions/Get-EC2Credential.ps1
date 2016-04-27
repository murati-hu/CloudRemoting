
function Get-EC2Credential {
    param(
        [Parameter(ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance]$InstanceObject,

        [Parameter(Mandatory, ParameterSetName="ByInstanceId")]
        [string]$InstanceId,

        [Parameter(Mandatory, ParameterSetName="ByInstanceId")]
        #[ValidateScript]
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
