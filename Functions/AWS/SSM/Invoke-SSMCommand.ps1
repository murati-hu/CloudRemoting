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
        [System.Int32]$TimeoutSecond
    )

    Begin {
        Add-Type -AssemblyName System.Web
    }

    Process {
        if ($Reservation) { $Instance = $Reservation.Instances }

        if (-Not $InstanceId) {
            Write-Verbose "Expanding InstanceId and Region from instance set"
            $InstanceId = $Instance | Select-Object -ExpandProperty InstanceId
            $Region = ($Instance | Select-Object -ExpandProperty Placement -First 1 | Select-Object -ExpandProperty AvailabilityZone) -replace '\w$',''
        }

        if (-Not $Region) {
            Write-Warning "Region is not set, execution may fail.."
        } else {
            Write-Verbose "Setting region to $Region .."
            Set-DefaultAWSRegion -Region $Region
        }

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
            $Parameter = @{'commands'=@(
                '$ConfirmPreference = "None"'
                $ScriptBlock.ToString()
            )}
        }
        
        if (-Not $instanceId) {
            Write-Warning "No instances to target, quiting."
            continue
        }

        Write-Verbose "Targeting instances: $instanceId"
        Write-Verbose "Executing $DocumentName with $($Parameter | Out-String).."

        $SSMCommandArgs = @{
            InstanceId=$InstanceId
            DocumentName=$DocumentName
            Comment="Invoked by $($env:USERNAME)@$($env:USERDOMAIN) from CloudRemoting@$($env:COMPUTERNAME)"
        }

        if ($Parameter) { $SSMCommandArgs.Parameter = $Parameter }
        if ($OutputS3BucketName) { $SSMCommandArgs.OutputS3BucketName = $OutputS3BucketName }
        if ($OutputS3KeyPrefix) { $SSMCommandArgs.OutputS3KeyPrefix = $OutputS3KeyPrefix }
        if ($TimeoutSecond) { $SSMCommandArgs.TimeoutSecond = $TimeoutSecond }

        try {
            $ssmCommand=Send-SSMCommand @SSMCommandArgs
        } catch {
            Write-Error $_.Exception
            continue
        }

        $Done = $false
        while(-Not $Done) {
            Write-Verbose "Waiting for $($ssmCommand.CommandId) - $($ssmCommand.Status) command..."
            $ssmCommand=Get-SSMCommand -CommandId $ssmCommand.CommandId -ErrorAction SilentlyContinue
            $Done = ($null -eq $ssmCommand) -or ($ssmCommand.Status -imatch 'Success|Fail')
        }

        foreach ($i in $InstanceId) {
            Write-Verbose "Returning results from $i .."
            $invocation = Get-SSMCommandInvocation -CommandId $ssmCommand.CommandId -Details $true -InstanceId $i
            if ($invocation.TraceOutput) { Write-Warning $invocation.TraceOutput }

            $result = $invocation | Select-Object -ExpandProperty CommandPlugins
            if ($result.Status -ine 'Success') {
                Write-Error "$($result.Name) Invocation failed on '$i' with ResponseCode $($result.ResponseCode)."
            }

            if (-Not $result.Output) { Write-Warning "No output was received from '$i'" }
            $output = $result.Output
            
            Write-Debug "Raw content received.."
            Write-Debug $output
            try {
                Write-Verbose "Decoding output.."
                $output = [System.Web.HttpUtility]::HtmlDecode($result.Output)
            } catch {
                Write-Error "Unable to XML Decode output"
            }

            Write-Verbose "Separating ErrorStream.."
            $ERROR_REGEX = '-+ERROR-+'
            if ($output -imatch $ERROR_REGEX) {
                $streams = $output -isplit $ERROR_REGEX
                $output = $streams[0]
                Write-Error "$i $($streams[1])"
            }

            Write-Verbose "Checking truncation.."
            $TRUNCATE_REGEX = '-+Output truncated-+'
            if ([string]::IsNullOrWhiteSpace($output) -or $output -imatch $TRUNCATE_REGEX) {
                if (-NOT $OutputS3BucketName -or -not $OutputS3KeyPrefix) {
                    Write-Warning "Output is truncated from '$i'."
                    Write-Warning "In order to get full output, set -OutputS3BucketName and -OutputS3KeyPrefix"
                } else {
                    Write-Verbose "Fetching full output from 's3://$OutputS3BucketName/$OutputS3KeyPrefix'"
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    Read-S3Object -BucketName $result.OutputS3BucketName -Key "$($result.OutputS3KeyPrefix)/stdout.txt" -File $tempFile | Out-Null
                    $output = Get-Content -Path $tempFile -Raw
                    Remove-Item -Path $tempFile -Force -Recurse

                    Write-Debug "Full content downloaded.."
                    Write-Debug $output
                }
            }

            if ($EnableCliXml) {
                Write-Verbose "Try Parsing output as CMLIXML"
                try {
                    $cliXml = [System.IO.Path]::GetTempFileName()
                    Set-Content -Path $cliXml -Value $output
                    $output = Import-Clixml -Path $cliXml
                    Remove-Item -Path $cliXml -Force
                } catch {
                    Write-Error $_.Exception
                }
            }

            Write-Verbose "Returning output.."
            $output
        }
    }
}