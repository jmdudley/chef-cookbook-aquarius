# Retrieve sensitive information from Chef databag
ruby_block 'get credentials from encrypted data bag' do
  block do
    databag_item = data_bag_item(node['aq_config']['databag'], node['aq_config']['databag_item'])
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

# Add directory to server for helper scripts
directory 'C:\\helper_scripts' do
  action :create
  inherits true
  ignore_failure true
end

# Retrieve helper scripts
node['aq_config']['helpers'].each do |filename, src|
  remote_file "C:\\helper_scripts\\#{filename}" do
    source src
    action :create
  end
end

# Create AQ database configuration file
template 'C:/ProgramData/Aquatic Informatics/AQUARIUS/AquariusDataSource.xml' do
  source 'AquariusDataSource.xml.erb'
  action :create
  variables(
    lazy {
      {
        db_username: node.run_state['db_username'],
        db_password: node.run_state['db_password'],
        db_server_name: node.run_state['db_server_name'],
        db_name: node.run_state['db_name']
      }
    }
  )
end

# Configure performance counters
powershell_script 'AQ Perfmon Config' do
  code <<-EOH
  $percounters="#{node['aq_config']['perfcounters_location']}"
  if ( (& "C:/Windows/system32/logman" query AQPerfCounters) -like '*Data Collector Set was not found*' ) {
    (New-Object System.Net.WebClient).DownloadFile($percounters, "C:/PerfLogs/AquariusPerformanceCounters.xml")
    & "C:/Windows/system32/logman" import AQPerfCounters -xml "C:/PerfLogs/AquariusPerformanceCounters.xml"
    & "C:/Windows/system32/logman" start AQPerfCounters
  } else {
    echo "AQPerfCounters Data Collector Set already exists"
  }
  EOH
  action :run
  ignore_failure true
end
# Create a redirect file for IIS
file 'C:\\inetpub\\wwwroot\\index.html' do
  content '<html><head><meta http-equiv="refresh" content="0; URL=\'/AQUARIUS/\'" /></head></html>'
  action :create
end
# Set the number of concurrent event processors
powershell_script 'AQ Eventprocessors Config' do
  code <<-EOH
  $num_procs="#{node['aq_config']['relative_event_processors']}"
  if (Test-Path "C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\EventProcessor\\EventProcessor.exe.Config") {
    $config_path="C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\EventProcessor\\EventProcessor.exe.Config"
  } elseif (Test-Path "C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\EventProcessor.exe.Config") {
    $config_path="C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\EventProcessor.exe.Config"
  }
  [xml]$myXML = Get-Content $config_path
  If ( $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']").Count -gt 0 ) {
    if ( $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']/@value").Item(0).Value -ne $num_procs ) {
      $myXML.SelectNodes("//configuration/appSettings/add[@ key='ConcurrentActionLimit']/@value").Item(0).Value=$num_procs
      $myXML.Save($config_path)
    }
  } else {
    $child = $myXML.CreateElement("add")
    $child.SetAttribute("key","ConcurrentActionLimit")
    $child.SetAttribute("value",$num_procs)
    $myXML.SelectNodes("//configuration/appSettings").item(0).AppendChild($child)
    $myXML.Save($config_path)
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

# Configure https on the server if needed
if node['aq_config']['enable_https']
  include_recipe 'aq_installation::config_https'
end
include_recipe 'aq_installation::config_blob_store'
