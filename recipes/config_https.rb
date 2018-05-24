# Configure AQ HTTPS
require 'open-uri'
aquarius_data_bag = data_bag_item(node['aq_config']['databag'], node['aq_config']['databag_item'])
cert_pass = aquarius_data_bag['cert_password']
cert_name = aquarius_data_bag['cert_name']

# Retrieve SSL certificate
remote_file "C:\\#{cert_name}" do
  source node['config_https']['cert_location']
  action :create
  inherits true
  ignore_failure false
end

# Configure SSL on IIS using certificate
ruby_block 'configure https' do
  block do
    cur_bindings = `\"C:\\Windows\\System32\\inetsrv\\appcmd.exe\" list site`
    if cur_bindings.include? 'https/*:443:'
      Chef::Log.info('Server is already configured for HTTPS')
    else
      Chef::Log.info('Enabling HTTPS')
      if File.file?('C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\HttpsConfigurationTool.exe')
        httpstool = 'C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\HttpsConfigurationTool.exe'
      elsif File.file?('C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\HttpsConfigurationTool.exe')
        httpstool = 'C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\HttpsConfigurationTool.exe'
      else
        Chef::Log.error('Unable to find HttpsConfigurationTool.exe!!!')
      end
      configout = `\"#{httpstool}\" -c\"C:\\#{cert_name}\" -p#{cert_pass}`
      Chef::Log.error('Unable to configure HTTPS') unless configout.to_s.empty?
    end
  end
end
