# Default attributes for aq_installation cookbook

# Should the server be configured for SSL
default['aq_config']['enable_https'] = true

# Location of custom xsl BLOB transform file
default['aq_config']['xsl_report_url'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/test.xsl'

# Data bag names which contains secrets for server configuration
default['aq_config']['databag'] = 'test-databag'
default['aq_config']['databag_item'] = 'databag-item'
default['license_aq']['license_databag_item'] = 'license-databag-item'

# Number of EventProcessor.exe processes relative to CPU count
default['aq_config']['relative_event_processors'] = '-1'

# Location of AQUARIUS Time Series Server installation archive
default['aq_install']['install_file'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/install.zip'

# Location of certificate used to configure SSL
default['config_https']['cert_location'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/AQUARIUS_SERVER_POOL_CERTIFICATE.pfx'

# Location of perfomance monitoring counters file
default['aq_config']['perfcounters_location'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/perfcounters.xml'

# Location of additional helper scripts
default['aq_config']['helpers']['check_vitals.ps1'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/helpers/helperfile1.txt'
default['aq_config']['helpers']['AQ_services.ps1'] = 'file:///C:/Users/Administrator/AppData/Local/Temp/kitchen/data/helpers/helperfile2.txt'

# AWS Region where BLOB bucket is located
default['config_blob_store']['aws_region'] = 'us-west-2'