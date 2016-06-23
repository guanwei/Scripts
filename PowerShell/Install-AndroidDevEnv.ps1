$jdkDownloadUrl = "http://download.oracle.com/otn-pub/java/jdk/8u91-b15/jdk-8u91-windows-x64.exe"
$jdkTempFile = "C:\jdk-8u91-windows-x64.exe"
Invoke-WebRequest -Uri $jdkDownloadUrl -OutFile $jdkTempFile
