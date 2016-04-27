<#
.SYNOPSIS
    Opens an RDP Session to a target machine
.DESCRIPTION
    Opens mstsc.exe with the passed -ComputerName parameter.

    If -Credential is set, it will use cmdkey.exe to save the credential
    for passthrough.

.PARAMETER ComputerName
    Mandatory - ComputerName, IpAddress or fqdn of the target machine
.PARAMETER Credential
    Optional - Credential objeect to be passed to the remote desktop session.
.PARAMETER CleanupCredentials
    Optional - Switch to remove any related credentials when the RDP session
    exits.

.EXAMPLE
    Enter-RdpSession -ComputerName 'dc01.local'
.EXAMPLE
    $cred = Get-Credential
    Enter-RdpSession -ComputerName 'dc01.local' -Credential $cred
#>
function Enter-RdpSession {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUsePSCredentialType", "Credential")]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [switch]$CleanupCredentials
    )

    $rdcProcess = New-Object System.Diagnostics.Process
    if ($Credential) {
        $Password = ''
        if ($Credential.GetNetworkCredential()) {
            $Password=$Credential.GetNetworkCredential().password
        } else {
            $Password=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.password))
        }

        Write-Verbose "Adding Credentials for $ComputerName to Windows Credential Store"
        $rdcProcess.StartInfo.FileName = [Environment]::ExpandEnvironmentVariables("%SystemRoot%\system32\cmdkey.exe")
        $rdcProcess.StartInfo.Arguments = "/generic:TERMSRV/$ComputerName /user:$($Credential.UserName) /pass:`"$Password`""
        [void]$rdcProcess.Start()
    }

    Write-Verbose "Connecting to RDP Session: $ComputerName"
    $rdcProcess.StartInfo.FileName = [Environment]::ExpandEnvironmentVariables("%SystemRoot%\system32\mstsc.exe")
    $rdcProcess.StartInfo.Arguments = "/v $ComputerName"
    [void]$rdcProcess.Start()


    if ($CleanupCredentials) {
        Write-Verbose "Waiting for RDP Session to exit..."
        [void]$rdcProcess.WaitForExit()
        if ($Credential) {
            Write-Verbose "Removing Credentials from Windows Credential Store"
            $rdcProcess.StartInfo.FileName = [Environment]::ExpandEnvironmentVariables("%SystemRoot%\system32\cmdkey.exe")
            $rdcProcess.StartInfo.Arguments = "/delete:TERMSRV/$ComputerName"
            [void]$rdcProcess.Start()
        }
    }
}
