# Configure BLOB storage location
require 'open-uri'
require 'json'

identity_document = open('http://169.254.169.254/latest/dynamic/instance-identity/document').read
parsed_identity_doc = JSON.parse(identity_document)
region_id = parsed_identity_doc['region'].delete('-')

ruby_block 'configure BLOB store' do
  block do
    aquarius_data_bag = data_bag_item(node['aq_config']['databag'], node['aq_config']['database_databag'])
    s3_bucket = aquarius_data_bag['s3_blob_bucket']
    blob_id = aquarius_data_bag['s3_blob_id']
    blob_key = aquarius_data_bag['s3_blob_key']
    cur_blob_config = `powershell -Command \"(& 'C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\StorageTool.exe' show S3blob)\"`
    if cur_blob_config.include? 'ERROR: ORA-12154: TNS:could not resolve the connect identifier specified'
      Chef::Log.info('Unable resolve specified database...')
      Chef::Log.info("#{cur_blob_config}")
      Chef::Log.info('The database configuration may not have run yet, or there is an issue connecting to the database.')
    elsif cur_blob_config.include? 'ERROR: Failed to read DB configuration from'
      Chef::Log.info('Unable to get database configuration from file...')
      Chef::Log.info("#{cur_blob_config}")
      Chef::Log.info('The database configuration may not have run yet, or there is an issue connecting to the database.')
    else
      if cur_blob_config.include? 'AccessKeyId=' && 'BucketName=' && 'SecretAccessKey='
        cur_bucket = cur_blob_config.split("\n").grep(/BucketName=/)[0].split('=').last.strip
        cur_id =  cur_blob_config.split("\n").grep(/AccessKeyId=/)[0].split('=').last.strip
        cur_key = cur_blob_config.split("\n").grep(/SecretAccessKey=/)[0].split('=').last.strip
      else
        Chef::Log.info('Current configuration for the S3 bucket for BLOB storage is incomplete...')
        cur_bucket = 'NO=BLOBSTORECONFIGURED'
      end
      if cur_bucket != s3_bucket || cur_id != blob_id || cur_key != blob_key
        Chef::Log.info('Current configuration does not match what is in Chef databag...')
        Chef::Log.info('Configuring the S2blob storage provider...')
        configout = `\"C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\storagetool.exe\" set S3blob /Type=AmazonS3 /BucketName=#{s3_bucket} /AccessKeyId=#{blob_id} /SecretAccessKey=#{blob_key} /RegionId=#{region_id} /virtualrootpath=/aquarius/static`
        if configout.include? 'S3blob: Connectivity status = GOOD'
          Chef::Log.info('The S3 bucket for BLOB storage has been configured as: #{s3_bucket}')
          Chef::Log.info('Activating the S3 bucket for BLOB storage...')
          activateout = `\"C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\WebServices\\bin\\storagetool.exe\" Activate S3blob`
          if activateout.include? 'Activated provider S3blob'
            Chef::Log.info("The S3 bucket for BLOB storage has been activated as: #{s3_bucket}")
            # AT THIS POINT WE MAY WANT TO LOOK AT RESTARTING AQ SERVICES ON ALL SERVERS WITHIN THE ASG SINCE IT SEEMS THE CREDENTIALS ARE CACHED
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
end
