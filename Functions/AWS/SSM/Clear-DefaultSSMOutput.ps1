<#
.SYNOPSIS
    Clears the default S3 output settings for SSM
.DESCRIPTION
    The cmdlet clears a previously set Default S3 Output
    setting for SSM

.EXAMPLE
    Clear-DefaultSSMOutput
#>
function Clear-DefaultSSMOutput {
    Write-Verbose "Clearing SSM S3 Output settings.."
    $Script:DefaultSSMOutputS3BucketName=$null
    $Script:DefaultSSMOutputS3KeyPrefix=$null
}
