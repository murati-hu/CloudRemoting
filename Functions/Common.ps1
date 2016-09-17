# Common Aliases
New-Alias -Name rdp -Value Enter-RdpSession -Force
New-Alias -Name ec2rdp -Value Enter-EC2RdpSession -Force

New-Alias -Name ec2sn -Value Enter-EC2PSSession -Force

$script:DefaultEc2PemFile=$null
