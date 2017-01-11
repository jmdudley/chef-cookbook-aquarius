# license Aquarius software

ruby_block 'license aquarius' do
    block do
        cur_lic = `\"C:/Program Files/Aquatic Informatics/AQUARIUS Licence Manager/AutoActivate.exe\" show`
        unless cur_lic.include? "IsActivated=True IsEnabled=True"
            Chef::Log.info("Activating AQ license")
            aquarius_data_bag = data_bag_item(node['aq_config']['databag'], 'aq_license')
            license_key = aquarius_data_bag['license_code']
            # execute a powershell command from ruby
            activation = `\"C:/Program Files/Aquatic Informatics/AQUARIUS Licence Manager/AutoActivate.exe\" activate #{license_key}`
            if activation.include? "ERROR: Unable to activate licence."
                Chef::Log.error("Unable to aquire AQ license")
            else
                Chef::Log.info("Server successfully licensed...Restarting AQ services...")
                system('powershell -ExecutionPolicy Bypass -File C:\helper_scripts\AQ_services.ps1 restart')
            end
        else
            Chef::Log.info("Server already has an active AQ license")
        end
    end
end