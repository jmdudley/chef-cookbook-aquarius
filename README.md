# aq_installation-cookbook

Installs and configures AQUARIUS Time-Series Server on Windows Server.

## Platforms

- Windows Server 2008R2
- Windows Server 2012
- Windows Server 2016

## Attributes

- `['aq_config']['enable_https']` - Whether or not to configure IIS to also use SSL
- `['aq_config']['xsl_report_url']` - Location of XSL file used for custom BLOB transformation
- `['aq_config']['databag']` - Chef data bag name which contains needed databag items.
- `['aq_config']['databag_item']` - Data bag item specific to environment.
- `['license_aq']['license_databag_item']` - Data bag item containing AQUARIUS Server licence.
- `['aq_config']['relative_event_processors']` - Number of eventprocessor.exe processes relative to the number of available CPUs.
- `['aq_install']['install_file']` - Location of the AQUARIUS Time-Series Server software archive file.
- `['config_https']['cert_location']` - Location of the SSL certificate to be used when configuring IIS for SSL.
- `['aq_config']['perfcounters_location']` - Location of the performance monitoring counters file.
- `['aq_config']['helpers']['check_vitals.ps1']` - Whether or not to configure IIS to also use SSL
- `['aq_config']['helpers']['AQ_services.ps1']` - Whether or not to configure IIS to also use SSL
- `['config_blob_store']['aws_region']` - The AWS region in which the S3 BLOB storage bucket resides.</td>

## Usage

### aq_installation::default

Include `aq_installation` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[aq_installation::default]"
  ]
}
```

