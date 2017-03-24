# license Aquarius software

ruby_block 'license aquarius' do
  block do
    if `powershell -Command \"(Get-service -name AquariusAutomationService).StartType\"`.include? 'Automatic'
      cur_lic = `\"C:/Program Files/Aquatic Informatics/AQUARIUS Licence Manager/AutoActivate.exe\" show`
      if cur_lic.include? 'IsActivated=True IsEnabled=True'
        Chef::Log.info('Server already has an active AQ license')
      else
        Chef::Log.info('Activating AQ license')
        aquarius_data_bag = data_bag_item(node['aq_config']['databag'], 'aq_license')
        license_key = aquarius_data_bag['license_code']
        # execute a powershell command from ruby
        activation = `\"C:/Program Files/Aquatic Informatics/AQUARIUS Licence Manager/AutoActivate.exe\" activate #{license_key}`
        if activation.include? 'ERROR: Unable to activate licence.'
          Chef::Log.error('Unable to aquire AQ license')
        else
          Chef::Log.info('Server successfully licensed...Restarting AQ services...')
          Chef::Log.info(`powershell -ExecutionPolicy Bypass -File C:\\helper_scripts\\AQ_services.ps1 restart`)
        end
      end
    else
      Chef::Log.info('It seems the AQ services are not currently enabled so we will try again later')
    end
  end
end
