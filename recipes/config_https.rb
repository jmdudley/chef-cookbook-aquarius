# Configure AQ HTTPS

ruby_block 'configure https' do
  block do
    cur_bindings = `\"C:\\Windows\\System32\\inetsrv\\appcmd.exe\" list site`
    if cur_bindings.include? 'https/*:443:'
      Chef::Log.info('Server is already configured for HTTPS')
    else
      Chef::Log.info('Enabling HTTPS')
      aquarius_data_bag = data_bag_item(node['aq_config']['databag'], node['aq_config']['database_databag'])
      cert_pass = aquarius_data_bag['cert_password']
      cert_name = aquarius_data_bag['cert_name']
      tier = node['aq_config']['tier']
      bucket = node['aq_config']['config_bucket']
      if File.file?("C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\HttpsConfigurationTool.exe")
        httpstool = "C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\HttpsConfigurationTool.exe"
      elsif File.file?("C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\HttpsConfigurationTool.exe")
        httpstool = "C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\HttpsConfigurationTool.exe"
      else
        Chef::Log.error('Unable to find HttpsConfigurationTool.exe!!!')
      end
      `\"C:\\Program Files\\Amazon\\AWSCLI\\aws\" s3 cp \"s3://#{bucket}Application/aquarius/configuration/#{tier}/asg_certs/#{cert_name}\" \"C:\\#{cert_name}\"`
      configout = `\"#{httpstool}\" -c\"C:\\#{cert_name}\" -p#{cert_pass}`
      unless configout.to_s.empty?
        Chef::Log.error('Unable to configure HTTPS')
      end
    end
  end
end
