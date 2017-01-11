include_recipe 'windows::reboot_handler'
require "open-uri"

instance_id = open("http://169.254.169.254/latest/meta-data/instance-id") {|f| f.readline}


powershell_script 'rename computer to instance_id' do
    code <<-EOH
    & Rename-Computer -NewName #{instance_id} -force
    EOH
    action :run
end


ruby_block 'join domain' do
    block do
        domain = 'caws.us-west-2.compute.internal'
        encryption_key = 'C:/Users/Administrator/.ssh/caws_encryption_key'
        active_directory_databag = data_bag_item('caws_active_directory', 'caws_ad', IO.read(encryption_key))
        username = active_directory_databag['username']
        password = active_directory_databag['password']
        exec "NetDom join #{instance_id} /d:#{domain} /ud:#{username} /pd:#{password} /reboot:30"
    end
end