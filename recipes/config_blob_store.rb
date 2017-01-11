#Configure BLOB storage location
require "open-uri"
require "json"


identity_document = open("http://169.254.169.254/latest/dynamic/instance-identity/document").read
parsed_identity_doc = JSON.parse(identity_document)
region_id = parsed_identity_doc['region'].gsub('-', '')

ruby_block 'configure BLOB store' do
    block do
        aquarius_data_bag = data_bag_item(node['aq_config']['databag'], node['aq_config']['database_databag'])
        s3_bucket = aquarius_data_bag['s3_blob_bucket']
        cur_blob_config = `powershell -Command \"(& 'C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\StorageTool.exe' show S3blob) | sls 'BucketName='\"`
		if cur_blob_config.to_s == ''
            cur_blob_config = 'NO=BLOBSTORECONFIGURED'
        end
        unless cur_blob_config.split("=").last.strip == s3_bucket
            Chef::Log.info("Configuring the S3 bucket for BLOB storage...")
            blob_id = aquarius_data_bag['s3_blob_id']
            blob_key = aquarius_data_bag['s3_blob_key']
            configout =`\"C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\storagetool.exe\" set S3blob /Type=AmazonS3 /BucketName=#{s3_bucket} /AccessKeyId=#{blob_id} /SecretAccessKey=#{blob_key} /RegionId=#{region_id} /virtualrootpath=/aquarius/static`
            if configout.include? "S3blob: Connectivity status = GOOD"
                Chef::Log.info("The S3 bucket for BLOB storage has been configured as: #{s3_bucket}")
                Chef::Log.info("Activating the S3 bucket for BLOB storage...")
                activateout =`\"C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\storagetool.exe\" Activate S3blob`
                if activateout.include? "Activated provider S3blob"
                    Chef::Log.info("The S3 bucket for BLOB storage has been activated as: #{s3_bucket}")
                else
                    Chef::Log.error("Unable to activate the #{s3_bucket} S3 bucket for BLOB storage: #{activateout}")
                end
            else
                Chef::Log.error("Unable to configure the #{s3_bucket} S3 bucket for BLOB storage: #{configout}")
            end
        else
            Chef::Log.info("The S3 bucket for BLOB storage is already configured as: #{s3_bucket}")
        end
    end
end