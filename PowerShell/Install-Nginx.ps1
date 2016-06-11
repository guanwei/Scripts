Param(
    [Parameter(Mandatory=$True)]
    [String]$Version,
    [Parameter(Mandatory=$False)]
	[System.String]$InstallPath = "C:\nginx"
)

$nginxDownloadUrl = "http://nginx.org/download/nginx-${Version}.zip"

if ($env:TEMP -eq $null)
{
  $env:TEMP = Join-Path $env:SystemDrive 'temp'
}
$nginxTempDir = Join-Path $env:TEMP "nginx"
if(!(Test-Path $nginxTempDir))
{
    New-Item $nginxTempDir -Force -ItemType Directory
}
$nginxTempFile = Join-Path $nginxTempDir "nginx.zip"

# downlaod nginx
Write-Output "Downloading Nginx from $nginxDownloadUrl to $nginxTempFile"
Invoke-WebRequest -Uri $nginxDownloadUrl -OutFile $nginxTempFile

# extract nginx
Write-Output "Extracting $nginxTempFile to $nginxTempDir..."
$shellApplication = new-object -com shell.application
$zipPackage = $shellApplication.NameSpace($nginxTempFile)
$destinationFolder = $shellApplication.NameSpace($nginxTempDir)
$destinationFolder.CopyHere($zipPackage.Items(),0x10)

# copy to install path
$nginxUnzipDir = Join-Path $nginxTempDir "nginx-${Version}"
if(Test-Path "$InstallPath")
{
    Remove-Item "$InstallPath" -Force -Recurse
}
Copy-Item "$nginxUnzipDir" "$InstallPath" -Force -Recurse

# download winsw
$winswDownloadUrl = "http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.18/winsw-1.18-bin.exe"
$winswFile = Join-Path "$InstallPath" "nginx-service.exe"
Write-Output "Downloading winsw from $winswDownloadUrl to $winswFile"
Invoke-WebRequest -Uri $winswDownloadUrl -OutFile $winswFile

# create nginx-service.xml
$str = @"
<service>
  <id>nginx</id>
  <name>Nginx Service</name>
  <description>High Performance Nginx Service</description>
  <logpath>$InstallPath\logs</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>8</keepFiles>
  </log>
  <executable>$InstallPath\nginx.exe</executable>
  <startarguments>-p "$InstallPath"</startarguments>
  <stopexecutable>$InstallPath\nginx.exe</stopexecutable>
  <stoparguments>-p "$InstallPath" -s stop</stoparguments>
</service>
"@
$file = Join-Path "$InstallPath" "nginx-service.xml"
Write-Output "Creating $file..."
$str | Out-File $file -Force

# create nginx-service.exe.config
$str = @"
<configuration>
  <startup>
    <supportedRuntime version="v2.0.50727" />
    <supportedRuntime version="v4.0" />
  </startup>
  <runtime>
    <generatePublisherEvidence enabled="false" />
  </runtime>
</configuration>
"@
$file = Join-Path "$InstallPath" "nginx-service.exe.config"
Write-Output "Creating $file..."
$str | Out-File $file -Force

# install nginx service
Write-Output "Installing Nginx service..."
if((cmd /c "$InstallPath\nginx-service.exe" status) -ne "NonExistent")
{
    cmd /c "$InstallPath\nginx-service.exe" uninstall
}
cmd /c "$InstallPath\nginx-service.exe" install

if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP" | Select -ExpandProperty Start) -ne "0")
{
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP" -Name Start -Value 0 -Type DWord
    Write-Output "You need restart your computer."
}
else
{
    Write-Output "Starting Nginx service..."
    cmd /c "$InstallPath\nginx-service.exe" start
}