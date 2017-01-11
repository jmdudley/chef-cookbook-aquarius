powershell_script 'rename computer' do
    code <<-EOH
    $webClient = New-Object Net.WebClient
    $instanceId = $webClient.DownloadString(\"http://169.254.169.254/latest/meta-data/instance-id\")
    If ($env:computername -ne $instanceId) {Rename-Computer -NewName $instanceId}
    EOH
    action :run
end