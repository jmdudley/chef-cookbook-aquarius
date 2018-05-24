# Aquarius Server and License Manager Install

# Check if already installed

# Get installation zip file
remote_file 'C:\\AQ_Server.zip' do
  source node['aq_install']['install_file']
  action :create
end

# Perform installation Server, License Manager, and tools
powershell_script 'install-aquarius-server' do
  not_if '(((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | `
    Where-Object { $_.GetValue( "DisplayName" ) -eq "AQUARIUS Time-Series Server" } ).Length `
    + ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") | `
    Where-Object { $_.GetValue( "DisplayName" ) -eq "AQUARIUS Licence Manager" } ).Length) -gt 1'
  code <<-EOH
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  function Unzip {
      param([string]$zipfile, [string]$outpath)
      try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
        $true
      } catch {
        $false
      }
  }
  $OSVer=(Get-WmiObject win32_operatingsystem).version
  #Install AQUARIUS Server Software
  Unzip C:\\AQ_Server.zip C:\\AQ_Server_Install
  Unzip (Get-Childitem -Path C:\\AQ_Server_Install -Filter "AQUARIUS*Server-Installation-Kit*" -recurse).FullName C:\\AQ_Server_Install\\ServerInstallation
  $AQ_LM_install_path = (Get-Childitem -Path C:\\AQ_Server_Install\\ServerInstallation -Filter "AQLicenceManager.msi" -recurse).FullName
  if (Test-Path $AQ_LM_install_path) {
      Start-Process C:\\Windows\\System32\\msiexec.exe -ArgumentList "/i $AQ_LM_install_path /q" -wait
  }
  else {
      write-output "NO AQUARIUS LICENCE MANAGER INSTALLATION FILE FOUND"
  }
  $AQ_SRV_install_path = (Get-Childitem -Path C:\\AQ_Server_Install\\ServerInstallation -Filter "AQUARIUS*Server*.exe" -recurse).FullName
  if (Test-Path $AQ_SRV_install_path) {
      Start-Process $AQ_SRV_install_path -ArgumentList "/s /v/qn" -wait
  }
  else {
      write-output "NO AQUARIUS SERVER INSTALLATION FILE FOUND"
  }
  #Install the HTTPS config tool
  if (Test-Path "C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\AQUARIUSManager.exe") {
      Unzip (Get-Childitem -Path C:\\AQ_Server_Install -Filter "HttpsConfigurationTool.zip" -recurse).FullName "C:\\Program Files\\Common Files\\Aquatic Informatics\\AQUARIUS\\"
  }
  elseif ("C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\AQUARIUSManager.exe") {
      Unzip (Get-Childitem -Path C:\\AQ_Server_Install -Filter "HttpsConfigurationTool.zip" -recurse).FullName "C:\\Program Files\\Aquatic Informatics\\AQUARIUS Server\\bin\\" -ErrorAction SilentlyContinue
  }
  else {
      write-output "Unable to install HttpsConfigurationTool"
  }
  #Remove-Item C:\\AQ_Server_Install\\ -Recurse -Force
  #Remove-Item C:\\AQ_Server.zip -Recurse -Force
  EOH
end
