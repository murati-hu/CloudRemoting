<#
.SYNOPSIS
    Invokes an AWS SSM Command against EC2 instances

.DESCRIPTION
    This command is an extension for AWS PowerShell module to execute
    script on EC2 Instances similarly as Invoke-Command does on regular
    PSSessions.

    It takes direct EC2 instances or AWS reservation objects
    from pipeline and invokes SSM Commands on those.

    The specified -DocumentName and -Parameters will be executed
    synchronously and the response presented on the standard output.

    If -ScriptBlock is set the script will be executed within a
    'AWS-RunPowerShellScript' document.


.PARAMETER InstanceId
    Mandatory - EC2 Instance Id for the target machine
.PARAMETER Region
    Optinal - Region parameter for the EC2 Instance if -InstanceID is
    specified.

.PARAMETER Reservation
    Accepts an EC2 Reservation pipeline input from Get-Ec2Instance output.
.PARAMETER Instance
    Accepts an Amazon EC2 Instance object from the pipeline

.PARAMETER ScriptBlock
    Optional - Extra ScriptBlock to be executed as a PowerShell Block
    The block is executed as 'AWS-RunPowerShellScript'

.PARAMETER DocumentName
    SSM Document to be executed on the target EC2 Instances
    Default is 'AWS-RunPowerShellScript' to accept -ScriptBlock

.PARAMETER Parameter
    Optional - Parameter Hash to be passed as key-value pairs to
    the SSM Document.

.PARAMETER EnableCliXml
    Optional - Switch to enable PowerShell CliXml serialization
    for custom scriptblocks and deserialization for any response

.EXAMPLE
    Get-Ec2Instance | Invoke-SSMCommand { iisreset }

.EXAMPLE
    Invoke-SSMCommand { Resolve-DnsName 'google.com' } -InstanceId i-4660a819 -Region us-west-2

.EXAMPLE
    Get-Ec2Instance -InstanceId i-4660a819 -Region us-west-2 | Invoke-SSMCommand { whoami } -OutputS3BucketName 'my-bucket' -OutputS3KeyPrefix 'ssm-logs'

#>

function Invoke-SSMCommand {
    [CmdletBinding(DefaultParameterSetName='ByInstanceId')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","")]
    param(
        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceId")]
        [string[]]$InstanceId,

        [Parameter(ParameterSetName="ByInstanceId")]
        [string]$Region=$(Get-DefaultAWSRegion | Select-Object -ExpandProperty Region),

        [Parameter(Mandatory=$true,ParameterSetName="ByReservationObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Reservation]$Reservation,

        [Parameter(Mandatory=$true,ParameterSetName="ByInstanceObject", ValueFromPipeline=$true)]
        [Amazon.EC2.Model.Instance[]]$Instance,

        [Parameter()]
        [string]$DocumentName='AWS-RunPowerShellScript',

        [Parameter(Position=0)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1)]
        [hashtable]$Parameter,

        [Parameter()]
        [string]$OutputS3BucketName=$Script:DefaultSSMOutputS3BucketName,

        [Parameter()]
        [string]$OutputS3KeyPrefix=$Script:DefaultSSMOutputS3KeyPrefix,

        [Parameter()]
        [Alias('CliXml')]
        [switch]$EnableCliXml,

        [Parameter()]
        [System.Int32]$TimeoutSecond,

        [Parameter()]
        [System.Int32]$SleepMilliseconds=400
    )

    begin {
        Add-Type -AssemblyName System.Web
        $script:SSMInvocations = @{}

        Write-Verbose "Constructing Parameters.."
        if($DocumentName -eq 'AWS-RunPowerShellScript') {
            Write-Verbose "Running with generic PowerShell scriptblock.."
            if ($EnableCliXml) {
                Write-Verbose "Wrapping Scriptblock for CLIXML.."
                $Parameter = @{'commands'=@(
                    '$ConfirmPreference = "None"'
                    '$tempFile = [System.IO.Path]::GetTempFileName()'
                    "& { $($ScriptBlock.ToString()) } | Export-Clixml -Path `$tempFile"
                    'Get-Content -Path $tempFile'
                )}
            } else {
                $Parameter = @{'commands'=@(
                    '$ConfirmPreference = "None"'
                    $ScriptBlock.ToString()
                )}
            }
        }
        elseif ($DocumentName -eq 'AWS-RunShellScript') {
            Write-Verbose "Running with generic Shell ScriptBlock.."
            $Parameter = @{'commands'=@($ScriptBlock.ToString())}
        }
    }

    Process {
        # Convert all input into Instance list
        if ($Reservation) { $Instance = $Reservation.Instances }
        if ($InstanceId) {
            $Instance = $InstanceId |
            Foreach-Object {
                New-Object psobject -Property @{
                    InstanceId = $_
                    Placement = @{ AvailabilityZone="$($Region)x" }
                }
            }
        }

        Write-Debug "Processing $Instance ..."
        foreach ($i in $Instance) {
            $id = $i.InstanceId
            $Region = ($i | Select-Object -ExpandProperty Placement | Select-Object -ExpandProperty AvailabilityZone) -replace '\w$',''

            Write-Verbose "Targeting: $id @ $Region"
            Write-Verbose "Executing $DocumentName with `n $($Parameter.Keys | ForEach-Object { $Parameter.$_ | Out-String }).."

            if (-Not $Region) {
                Write-Warning "Region is not set, execution may fail.."
            } else {
                Write-Debug "Setting region to $Region .."
                Set-DefaultAWSRegion -Region $Region
            }

            $SSMCommandArgs = @{
                InstanceId=$id
                DocumentName=$DocumentName
                Comment="Invoked by $($env:USERNAME)@$($env:USERDOMAIN) from CloudRemoting@$($env:COMPUTERNAME)"
            }

            if ($Parameter) { $SSMCommandArgs.Parameter = $Parameter }
            if ($OutputS3BucketName) { $SSMCommandArgs.OutputS3BucketName = $OutputS3BucketName }
            if ($OutputS3KeyPrefix) { $SSMCommandArgs.OutputS3KeyPrefix = $OutputS3KeyPrefix }
            if ($TimeoutSecond) { $SSMCommandArgs.TimeoutSecond = $TimeoutSecond }

            try {
                $ssmCommand=Send-SSMCommand @SSMCommandArgs
                $script:SSMInvocations.$id = $ssmCommand
            } catch {
                Write-Error $_.Exception
                continue
            }
        }
    }

    end {
        Write-Verbose "Collecting results $($script:SSMInvocations)"

        while ($script:SSMInvocations.Keys.Count -gt 0) {
            $id = $script:SSMInvocations.Keys | Select-Object -First 1
            $i = $script:SSMInvocations.$id
            Write-Verbose "Waiting for $($i.InstanceIds) - $($i.CommandId) - $($i.Status) command..."
            $currentCommand=Get-SSMCommand -CommandId $i.CommandId -ErrorAction SilentlyContinue

            if (($null -eq $currentCommand) -or ($currentCommand.Status -imatch 'Success|Fail')) {
                $script:SSMInvocations.Remove($id)
                Get-SSMCommandResult -CommandId $i.CommandId -InstanceId $id -EnableCliXml:$EnableCliXml
            }
            Start-Sleep -Milliseconds $SleepMilliseconds
        }
    }
}
