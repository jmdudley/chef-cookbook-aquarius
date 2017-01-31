=begin
default attributes for aq installation cookbook
=end

default['aq_config']['enable_https'] = false
default['aq_config']['xsl_report_url'] = 'ftp://ftpext.usgs.gov/pub/cr/la/ruston/Blob%20templates/WebApps.ServiceModel.ResponseDtos.Visits.VisitInfo.xsl'
default['aq_config']['database_databag'] = 'migration_db'
default['aq_config']['databag'] = 'aquarius-oregon-aquarius-development'
default['aq_config']['license_databag'] = 'aq_license_caws_dev'
default['aq_config']['relative_event_processors'] = '-1'
default['aquarius']['installation_folder'] = '20160913_2016.2_GA.zip'
