# install Aquarius
require "FileUtils"
require "open-uri"
require "json"

identity_document = open("http://169.254.169.254/latest/dynamic/instance-identity/document").read
parsed_identity_doc = JSON.parse(identity_document)
account_id = parsed_identity_doc['accountId']

source_file = "s3://config-bucket-#{account_id}/install-files/aquarius/#{node['aquarius']['installation_folder']}"
folder_name = Pathname.new(source_file).basename
base_name = File.basename(folder_name, '.zip')

# check if AQ installation files exist
aq_installed_86 = Dir.exists?('C:/Program Files (x86)/Aquatic Informatics/AQUARIUS Server')
aq_installed_64 = Dir.exists?('C:/Program Files/Aquatic Informatics/AQUARIUS Server')
aq_program_data = Dir.exists?('C:/ProgramData/Aquatic Informatics/AQUARIUS Server')
aq_license_manager = Dir.exists?('C:Program Files (x86)/Aquatic Informatics/AQUARIUS Licence Manager')
node.default[':aquarius'][':installer_zip'] = 'set in compile phase -- zip'  # if you see this line get printed in the output something went terribly wrong
node.default[':aquarius'][':installer_dir'] = 'set in compile phase -- dir'  # if you see this line get printed in the output something went terribly wrong

template 'C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\Config\\machine.config' do
	source "machine_config_4.0.30319.erb"
	action :create
	inherits true
end

template 'C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\CONFIG\\machine.config' do
	source "machine_config_2.0.50727.erb"
	action :create
	inherits true
end

# don't bother with install steps if already installed

if !aq_installed_86 and !aq_installed_64 # or !aq_program_data

    python 'get aquarius installer' do
        environment 'Path' => 'C:/Python27'
        code <<-EOH
import boto3

s3 = boto3.resource('s3')
account_id = "#{account_id}"
installation_folder = "#{node['aquarius']['installation_folder']}"
bucket_name = 'config-bucket-{0}'.format(account_id)
item_path = 'install-files/aquarius/{0}'.format(installation_folder)
target = "C:/Users/Administrator/Downloads/aquarius.zip"
s3.meta.client.download_file(bucket_name, item_path, target)
        EOH
    end
    
    windows_zipfile 'C:/Users/Administrator/Downloads/aquarius' do
        source 'C:/Users/Administrator/Downloads/aquarius.zip'
        action :unzip
    end
    
    ruby_block 'identify Aquarius Server install zip' do
        block do
            aq_dir = 'C:/Users/Administrator/Downloads/aquarius'
            aq_installation_path = File.expand_path("..",Dir.glob("#{aq_dir}/**/*\*aquarius-server-installation*")[0])
            puts 'this is where the installations zips are thought to be:'
            puts (aq_installation_path)
            installation_subdirs = Dir.entries(aq_installation_path)
            server_install_zip = 'some_value'
            (installation_subdirs).each do |i|
                i_down = i.downcase
                puts i_down
                if i_down.include? "aquarius-server-installation"
                    server_install_zip = i
                    break
                end
            end
            # node.set[':aquarius'][':installer_zip'] = "#{aq_installation_path}/#{server_install_zip}"
            node.run_state[':installer_zip'] = "#{aq_installation_path}/#{server_install_zip}"
            server_install_dir = File.basename(server_install_zip, '.zip')
            # node.set[':aquarius'][':installer_dir'] = "#{aq_installation_path}/#{server_install_dir}"
            node.run_state[':installer_dir'] = "#{aq_installation_path}/#{server_install_dir}"
        end
    end


    python 'unzip_aquarius_installer' do
        # resorting to this because windows_zip can't take a variable as its source
        # python has a native library for zip archives, so it seems logical...
        environment 'Path' => 'C:/Python27'
        code lazy {<<-EOH
import zipfile
aq_install_zip_path = "#{node.run_state[':installer_zip']}"
target_path = "#{node.run_state[':installer_dir']}"
print('Python -- aquarius installation zip path:')
print(aq_install_zip_path)
print('Python -- aquarius installation executable path:')
print(target_path)
with zipfile.ZipFile(aq_install_zip_path) as zf:
    zf.extractall(target_path)
        EOH
        }
    end
    
    windows_package 'install aquarius server' do
        # source "C:/Users/Administrator/Downloads/aquarius/#{base_name}/Server/AQUARIUSServerSetup.exe"
        source lazy {"#{node.run_state[':installer_dir']}/AQUARIUSServerSetup.exe"}
        installer_type :custom
        action :install
        timeout 600
        options '/s /v"/qn"'
    end
    
    windows_package 'install aquarius license manager' do
        # source "C:/Users/Administrator/Downloads/aquarius/#{base_name}/LicenceManager/AQLicenceManager.msi"
        source lazy {"#{node.run_state[':installer_dir']}/LicenceManager/AQLicenceManager.msi"}
        installer_type :msi
        action :install
        options '/q'
    end
    
    ruby_block 'remove_aquarius_install_files' do
        block do
            sleep(60)
            FileUtils.rm('C:/Users/Administrator/Downloads/aquarius.zip')
            FileUtils.rm_rf('C:/Users/Administrator/Downloads/aquarius')
        end
    end

end