
function Get-SSMCommandResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandId,

        [Parameter()]
        [string]$InstanceId,

        [Parameter()]
        [string]$Region=$(Get-DefaultAWSRegion | Select-Object -ExpandProperty Region),

        [Parameter()]
        [switch]$EnableCliXml
    )

    Write-Verbose "Fetching results from $InstanceId - $CommandId .."
    $invocation = Get-SSMCommandInvocation -CommandId $CommandId -Details $true -InstanceId $InstanceId
    if ($invocation.TraceOutput) { Write-Warning $invocation.TraceOutput }

    $result = $invocation | Select-Object -ExpandProperty CommandPlugins
    if ($result.Status -ine 'Success') {
        Write-Error "'$InstanceId': $($result.Name) invocation failed with ResponseCode $($result.ResponseCode)."
    }

    if (-Not $result.Output) { Write-Warning "No output was received from '$InstanceId'" }
    $output = $result.Output

    Write-Verbose "Raw output received.."
    Write-Verbose $output

    try {
        Write-Verbose "Trying to decode output.."
        $output = [System.Web.HttpUtility]::HtmlDecode($result.Output)
    } catch {
        Write-Error "Unable to XML Decode output."
    }

    Write-Verbose "Separating ErrorStream.."
    $ERROR_REGEX = '-+ERROR-+'
    if ($output -imatch $ERROR_REGEX) {
        $streams = $output -isplit $ERROR_REGEX
        $output = $streams[0]
        Write-Error "$i $($streams[1])"
    }

    Write-Verbose "Checking result truncation.."
    $TRUNCATE_REGEX = '-+Output truncated-+'
    if ([string]::IsNullOrWhiteSpace($output) -or $output -imatch $TRUNCATE_REGEX) {
        if ($result.OutputS3BucketName) {
            $S3Path = "s3://$($result.OutputS3BucketName)/$($result.OutputS3KeyPrefix)"

            try {
                Write-Verbose "Fetching full output from $S3Path"
                $tempFile = [System.IO.Path]::GetTempFileName()
                $pluginName = $result.Name -replace ':', ''
                Read-S3Object -BucketName $result.OutputS3BucketName -Key "$($result.OutputS3KeyPrefix)/0.$($pluginName)/stdout" -File $tempFile -Region $Region -ErrorAction Stop | Out-Null
                $output = Get-Content -Path $tempFile -Raw
                Remove-Item -Path $tempFile -Force -Recurse
            } catch {
                Write-Error "Unable to read full output from $S3Path"
                Write-Verbose $_.Exception
            }
        } else {
            Write-Warning "Unable to fetch full output. Please specify S3 Output, to receive non-truncated results."
        }
    }

    if ($EnableCliXml) {
        Write-Verbose "Try Parsing output as CliXml"
        try {
            $cliXml = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $cliXml -Value $output
            $output = Import-Clixml -Path $cliXml
            Remove-Item -Path $cliXml -Force
        } catch {
            Write-Debug $_.Exception
            Write-Error "Unable to parse result as CliXml"
        }
    }

    Write-Verbose "Returning output.."
    $output |
    Add-Member -NotePropertyName InstanceId -NotePropertyValue $InstanceId -ErrorAction Continue -PassThru |
    Add-Member -NotePropertyName SSMCommandInvocation -NotePropertyValue $invocation -ErrorAction Continue -PassThru
}
