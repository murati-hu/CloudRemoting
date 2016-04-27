CloudRemoting PowerShell module
===============================

[![Build status](https://ci.appveyor.com/api/projects/status/kdc6a75b8wludjq6?svg=true)](https://ci.appveyor.com/project/muratiakos/cloudremoting)

CloudRemoting module provides an easy and scriptable way to connect to EC2, Azure
or to other machines via RDP or PSRemoting sessions on top of the standard
cmdlets by:
 - Seamless EC2 Administrator Credential decryption for RDP and PSRemoting
 - Credential pass-through for RDP Sessions

## Installation
CloudRemoting is available via [PowerShellGallery][PowerShellGallery] and via
[PsGet][psget], so you can simply install it with the following command:
```powershell
# Install it from PowerShellGallery / PsGet repos
Install-Module CloudRemoting

# Or install it from this repository
Install-Module -ModuleUrl https://github.com/muratiakos/CloudRemoting/archive/master.zip
```
Of course you can download and install the module manually too from
[Downloads][download]

## Usage
```powershell
Import-Module CloudRemoting
```

## Few Examples
### EC2 Instance Remoting with Private-Key file
```powershell
# EC2 Administrator RDP Sessions
Get-Ec2Instance i-2492acfc | Enter-EC2RdpSession -PemFile '~/.ssh/myprivatekey.pem'

# EC2 Administrator PSRemoting
Get-Ec2Instance i-2492acfc | New-EC2PSSession -PemFile '~/.ssh/myprivatekey.pem'
```
All EC2 cmdlets relies on the official [`AWSPowershell`][AWSPowershell] module.
It expects the module to be installed with valid AWS credentials setup.


### RemoteDesktop to any machine
```powershell
# Connect an RDP Session to any machine
$c = Get-EC2Credential # Or retrieve from a persisted creds
Enter-RdpSession -ComputerName '207.47.222.251' -Credential $c
```

## Documentation
Cmdlets and functions for CloudRemoting have their own help PowerShell help, which
you can read with `help <cmdlet-name>`.

## Versioning
CloudRemoting aims to adhere to [Semantic Versioning 2.0.0][semver].

## Issues
In case of any issues, raise an [issue ticket][issues] in this repository and/or
feel free to contribute to this project if you have a possible fix for it.

## Development
* Source hosted at [Github.com][repo]
* Report issues/questions/feature requests on [Github Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the [repo][repo]
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors
Created and maintained by [Akos Murati][muratiakos] (<akos@murati.hu>).

## License
Apache License, Version 2.0 (see [LICENSE][LICENSE])

[repo]: https://github.com/muratiakos/CloudRemoting
[issues]: https://github.com/muratiakos/CloudRemoting/issues
[muratiakos]: http://murati.hu
[license]: LICENSE
[semver]: http://semver.org/
[psget]: http://psget.net/
[download]: https://github.com/muratiakos/CloudRemoting/archive/master.zip
[PowerShellGallery]: https://www.powershellgallery.com
[AWSPowershell]: https://aws.amazon.com/powershell
