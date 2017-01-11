#Configure AQ HTTPS

ruby_block 'configure https' do
    block do
        cur_bindings = `\"C:\\Windows\\System32\\inetsrv\\appcmd.exe\" list site`
        unless cur_bindings.include? "https/*:443:"
            Chef::Log.info("Enabling HTTPS")
            aquarius_data_bag = data_bag_item(node['aq_config']['databag'], node['aq_config']['database_databag'])
            cert_pass = aquarius_data_bag['cert_password']
            cert_name = aquarius_data_bag['cert_name']
            `\"C:\\Program Files\\Amazon\\AWSCLI\\aws\" s3 cp \"s3://devops-owi-configuration-management/application/aquarius/configuration/asg_certs/#{cert_name}\" \"C:\\#{cert_name}\"`
            configout = `\"C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\HttpsConfigurationTool.exe\" -c\"C:\\#{cert_name}\" -p#{cert_pass}`
            if configout.include? "ERROR: Unable to configure HTTPS."
                Chef::Log.error("Unable to configure HTTPS")
            end
        else
            Chef::Log.info("Server is already configured for HTTPS")
        end
    end
end