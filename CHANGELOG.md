# 0.2.19
* Added config_bucket location parameter for use between accounts

# 0.2.18
* Added tier parameter in order to seperate out s3 configuration files by tier
* Added check for HttpsConfigurationTool.exe location since it has changed in 2017.2GA

# 0.2.17
* Added check for StorageTool.exe location since it has changed in 2017.2GA

# 0.2.16
* Removed configuration of cloudwatch via EC2Config
* Parameterized the field report xsl url
* Added identification of ID and KEY changes to BLOB configuration
* Added check for AQ services being enabled before licensing

# 0.2.15
* Added restart of SSM service if cloudwatch config updated
* Fixed typo in Ec2Config service restart

# 0.2.14
* Added S3 BLOB storage config recipe
* Added restart of AQ services if license aquisition is required
* Added helper scripts download from S3

# 0.2.13
* Added HTTPS config recipe

# 0.2.12
* Changed licensing databag reference

# 0.2.11
* Added check and log entry for failure to aquire AQ license

# 0.2.10
* Added check for existing active AQ license to avoid constant relicensing

# 0.2.9
* Added EC2Config service restart via powershell since service resource fails if service is not running

# 0.2.8
* Added EC2Config Cloudwatch configuration to send logs and data to cloudwatch

# 0.2.7

* Adjusted Event processor config to only save file on change
* Added placement of stylesheet for field visit summary report
* Added checks to avoid unnecassary overwrites of files

# 0.2.6

* Added new data credential file
* Added Event processor # configuration
* Changed default Aquarius version to 2015.4 GA Update 1

# 0.2.5

* Use AWS instead of Vagrant for testing (not totally working yet)
* Minor changes to use chef-client 12.8
* Support Aquarius redirect using index.html

# 0.2.4

* Remove powershell_script resources from recipes that are used by Packer
* Use ruby_block resources to effect deletes and clean-up of items downloaded during provisioning
* Change default Aquarius version to 2015.4 GA

# 0.2.2

* machine.config configuration uses a template rather than a heredoc string
* Remove configuration of Framework64 machine.config files

# 0.2.1

* Set data bag and data bag items as attributes

# 0.2.0

* Support for Aquarius 64-bit
* Configure Framework and Framework64 machine.config
* Replace `powershell_script` resources with`python` resources

# 0.1.0

* Initial release of aq_installation
