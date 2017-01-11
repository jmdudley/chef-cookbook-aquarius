require "open-uri"
require "json"


identity_document = open("http://169.254.169.254/latest/dynamic/instance-identity/document").read
parsed_identity_doc = JSON.parse(identity_document)
account_id = parsed_identity_doc['accountId']
instance_id = open('http://169.254.169.254/latest/meta-data/instance-id'){|f| f.gets}

template_target = "C:/Users/Administrator/Downloads/AqDataSourceTemplate.xml"
config_target = "C:/ProgramData/Aquatic Informatics/AQUARIUS/AqDataSource.xml"


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
#Add directory for stylesheet to server
directory 'C:\\ProgramData\\Aquatic Informatics\\AQUARIUS Server\\Attachments\\templates' do
    action :create
    inherits true
    ignore_failure true
end
#Add report stylesheet to server
remote_file 'C:\\ProgramData\\Aquatic Informatics\\AQUARIUS Server\\Attachments\\templates\\WebApps.ServiceModel.ResponseDtos.Visits.VisitInfo.xsl' do
    source 'ftp://ftpext.usgs.gov/pub/cr/la/ruston/Blob%20templates/WebApps.ServiceModel.ResponseDtos.Visits.VisitInfo.xsl'
    action :create
    inherits true
    ignore_failure true
end

#Configure EC2Config to send logs and data to cloudwatch
powershell_script 'Get And Set EC2Config Config' do
    code <<-EOH
		$original_file = 'C:\\chef\\AWS.EC2.Windows.CloudWatch.json.tmp'
		$destination_file =  'C:\\chef\\AWS.EC2.Windows.CloudWatch.json'
		& "C:/Program Files/Amazon/AWSCLI/aws" s3 cp "s3://devops-owi-configuration-management/application/aquarius/configuration/AWS.EC2.Windows.CloudWatch.json" $original_file
		$ASG_name = (& "C:/Program Files/Amazon/AWSCLI/aws" autoscaling describe-auto-scaling-instances --region us-west-2 --instance-ids #{instance_id} | Out-string | ConvertFrom-Json).AutoScalingInstances.AutoScalingGroupName
		(Get-Content $original_file) | Foreach-Object {$_ -replace 'CLOUDWATCHAUTOSCALINGGROUPNAMEDIMENSION', $ASG_name} | Set-Content $destination_file
		Remove-Item $original_file
    EOH
    action :run
    ignore_failure true
end

remote_file 'C:\\Program Files\\Amazon\\Ec2ConfigService\\Settings\\AWS.EC2.Windows.CloudWatch.json' do
	source 'file:///chef/AWS.EC2.Windows.CloudWatch.json'
	action :create
	inherits true
	ignore_failure true
	#notifies :restart, "service[Ec2Config]"
	notifies :run, 'powershell_script[Restart Ec2Config services]', :immediately
end
powershell_script 'Restart Ec2Config services' do
	code <<-EOH
		If ((Get-Service -name Ec2Config).status -eq [System.ServiceProcess.ServiceControllerStatus]::Running ) {
			Try {Restart-Service Ec2Config -ErrorAction Stop} Catch {echo "Unable to restart Ec2Config Service"}
		}
		if ((Get-Service | Where-Object {$_.Name -eq "AmazonSSMAgent"}).length -eq 1) {
			If ((Get-Service -name AmazonSSMAgent).status -eq [System.ServiceProcess.ServiceControllerStatus]::Running ) {
				Try {Restart-Service AmazonSSMAgent -ErrorAction Stop} Catch {echo "Unable to restart AmazonSSMAgent Service"}
			}
		}
	EOH
    action :nothing
    ignore_failure true
end
if node['aq_config']['enable_https']
	include_recipe 'aq_installation::config_https'
end
include_recipe 'aq_installation::config_blob_store'
# Define EC2Config service
#service "Ec2Config" do
#  supports :status => true, :start => true, :stop => true, :restart => true
#  action :nothing
#end
#powershell_script 'IIS Advanced Logging Config' do
#    code <<-EOH
#    & "C:/Program Files/Amazon/AWSCLI/aws" s3 cp "s3://config-bucket-#{account_id}/install-files/iis/iis_advanced_logging_config.ps1" "C:/Users/Administrator/Downloads/iis_advanced_logging_config.ps1"
#    & "C:/Users/Administrator/Downloads/iis_advanced_logging_config.ps1"
#    EOH
#    action :run
#    ignore_failure true
#end