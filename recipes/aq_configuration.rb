require 'open-uri'
require 'json'

ruby_block 'get credentials from encrypted data bag' do
  block do
    databag_item = data_bag_item(node['aq_config']['databag'], node['aq_config']['database_databag'])
    password = databag_item['password']
    username = databag_item['username']
    server_name = databag_item['server_name']
    db_name = databag_item['db_name']
    node.run_state['db_password'] = password
    node.run_state['db_username'] = username
    node.run_state['db_server_name'] = server_name
    node.run_state['db_name'] = db_name
  end
  action :run
end
powershell_script 'Get helper scripts' do
  code <<-EOH
    & "C:/Program Files/Amazon/AWSCLI/aws" s3 cp "s3://devops-owi-configuration-management/application/aquarius/configuration/helper_scripts/" "C:/helper_scripts/" --recursive
  EOH
  action :run
  ignore_failure true
end
template 'C:/ProgramData/Aquatic Informatics/AQUARIUS/AquariusDataSource.xml' do
  source 'AquariusDataSource.xml.erb'
  action :create
  variables(
             lazy {
              {:db_username => node.run_state['db_username'],
               :db_password => node.run_state['db_password'],
               :db_server_name => node.run_state['db_server_name'],
               :db_name => node.run_state['db_name']
              }
             }
           )
end

powershell_script 'AQ Perfmon Config' do
  code <<-EOH
  if ( (& "C:/Windows/system32/logman" query AQPerfCounters) -like '*Data Collector Set was not found*' ) {
    & "C:/Program Files/Amazon/AWSCLI/aws" s3 cp "s3://devops-owi-configuration-management/application/aquarius/configuration/AquariusPerformanceCounters.xml" "C:/PerfLogs/AquariusPerformanceCounters.xml"
    & "C:/Windows/system32/logman" import AQPerfCounters -xml "C:/PerfLogs/AquariusPerformanceCounters.xml"
    & "C:/Windows/system32/logman" start AQPerfCounters
  } else {
    echo "AQPerfCounters Data Collector Set already exists"
  }
  EOH
  action :run
  ignore_failure true
end

file 'C:\\inetpub\\wwwroot\\index.html' do
  content '<html><head><meta http-equiv="refresh" content="0; URL=\'/AQUARIUS/\'" /></head></html>'
  action :create
end

powershell_script 'AQ Eventprocessors Config' do
  code <<-EOH
  $num_procs="#{node['aq_config']['relative_event_processors']}"
  [xml]$myXML = Get-Content "C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\EventProcessor\\EventProcessor.exe.Config"
  If ( $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']").Count -gt 0 ) {
    if ( $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']/@value").Item(0).Value -ne $num_procs ) {
      $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']/@value").Item(0).Value=$num_procs
      $myXML.Save("C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\EventProcessor\\EventProcessor.exe.Config")
    }
  } else {
    $child = $myXML.CreateElement("add")
    $child.SetAttribute("key","ConcurrentActionLimit")
    $child.SetAttribute("value",$num_procs)
    $myXML.SelectNodes("//configuration/appSettings").item(0).AppendChild($child)
    $myXML.Save("C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\EventProcessor\\EventProcessor.exe.Config")
  }
  EOH
  action :run
  ignore_failure true
end
# Add directory to server for stylesheet
directory 'C:\\ProgramData\\Aquatic Informatics\\AQUARIUS Server\\Attachments\\templates' do
  action :create
  inherits true
  ignore_failure true
end
# Add report stylesheet to server
remote_file 'C:\\ProgramData\\Aquatic Informatics\\AQUARIUS Server\\Attachments\\templates\\WebApps.ServiceModel.ResponseDtos.Visits.VisitInfo.xsl' do
  source node['aq_config']['xsl_report_url']
  action :create
  inherits true
  ignore_failure true
end
if node['aq_config']['enable_https']
  include_recipe 'aq_installation::config_https'
end
include_recipe 'aq_installation::config_blob_store'

# powershell_script 'IIS Advanced Logging Config' do
#  code <<-EOH
#  & "C:/Program Files/Amazon/AWSCLI/aws" s3 cp "s3://config-bucket-#{account_id}/install-files/iis/iis_advanced_logging_config.ps1" "C:/Users/Administrator/Downloads/iis_advanced_logging_config.ps1"
#  & "C:/Users/Administrator/Downloads/iis_advanced_logging_config.ps1"
#  EOH
#  action :run
#  ignore_failure true
# end
