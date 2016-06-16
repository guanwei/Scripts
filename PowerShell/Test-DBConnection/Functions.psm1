#
# 获取服务器列表.
#
function Get-Servers([string]$Servers)
{
    $serverlist = @()
    $Servers.split(',') | %{
        $s = $_.Trim()
        if ($s -match "([a-zA-Z]+)(\d+)-(\d+)")
        {
            for ([int]$i=$Matches[2];$i -le $Matches[3];$i++)
            {
                if($i -lt 10) { $server = $Matches[1]+"0"+$i } else { $server = $Matches[1]+$i }
                $serverlist += $server
            }
        }
        else
        {
            $serverlist += $s
        }
    }
    return $serverlist
}

#
# 测试数据库连接性.
#
function Test-SqlConnection
{
    param(
        [string[]]$Servers,
        [string]$DataSource,
        [string]$Database,
        [string]$UserName,
        [string]$Password
    )

    $returner = New-Object –TypeName PSObject –Prop @{'Success'=0;'Errors'=0;'Content'=@()}
    $connectionStr = "Data Source=$DataSource;Initial Catalog=$Database;user id=$UserName;pwd=$Password"
    $msg = "   ### " + $connectionStr.replace($Password,'******')
    Write-Host $msg -ForegroundColor White
    $returner.Content += $msg

    foreach($server in $Servers)
    {
        try
        {
            $fqdn = Get-WmiObject Win32_ComputerSystem -ComputerName $server -EA Stop | %{ if($_.PartOfDomain){"{0}.{1}" -f $_.Name,$_.Domain}else{$_.Name} }
            $result = Invoke-Command $fqdn -ArgumentList $connectionStr -ScriptBlock {
                try
                {
                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                    $SqlConnection.ConnectionString = $args[0]
                    $SqlConnection.Open()
                    $msg = "      [Success] ${env:ComputerName}: Connected to SQL server"
                    Write-Host $msg -Fore Green
                    $connected = $true
                }
                catch
                {
                    $msg = "      [Failed] ${env:ComputerName}: $_"
                    Write-Host $msg -Fore Red
                    $connected = $false
                }
                finally
                {
                    $SqlConnection.Dispose()
                }
                return (New-Object –TypeName PSObject –Prop @{'Connected'=$connected;'Message'=$msg})
            }
            if($result.Connected)
            {
                $returner.Content += $result.Message
                $returner.Success ++
            }
            else
            {
                $returner.Content += $result.Message
                $returner.Errors ++
            }
        }
        catch
        {
            $msg = "      [Failed] ${server}: $_"
            Write-Host $msg -Fore Red
            $returner.Content += $msg
            $returner.Errors ++
        }
    }
    return $returner
}

#
# 建立数据库连接.
#
function New-SqlConnection([string]$ConnectionStr)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $ConnectionStr
    try{
        $SqlConnection.Open()
        Write-Host 'Connected to sql server.'
        #return $SqlConnection
        $SqlConnection.Close()
    }
    catch [exception] {
        Write-Warning ('Connect to database failed with error message:{0}' -f ,$_)
        $SqlConnection.Dispose()
        return $null
    }
}
 
#
# 查询返回一个DataTable对象
#
function Get-SqlDataTable
{
    param
    (
    [System.Data.SqlClient.SqlConnection]$SqlConnection,
    [string]$query
    )
    $dataSet = new-object "System.Data.DataSet" "WrestlersDataset"
    $dataAdapter = new-object "System.Data.SqlClient.SqlDataAdapter" ($query,$SqlConnection)
    $dataAdapter.Fill($dataSet) | Out-Null
    return $dataSet.Tables | select -First 1
}
 
#
# 执行一条SQL命令
#
function Execute-SqlCommandNonQuery
{
    param
    (
    [System.Data.SqlClient.SqlConnection]$SqlConnection,
    [string]$Command
    )
    $cmd = $SqlConnection.CreateCommand()
    try
    {
        $cmd.CommandText = $Command
        $cmd.ExecuteNonQuery() | Out-Null
        return $true
    }
    catch [Exception] {
         Write-Warning ('Execute Sql command failed with error message:{0}' -f $_)
         return $false
    }
    finally{
        $SqlConnection.Close()
    }
}

#
# 通过事物处理执行多条SQL命令
#
function Execute-SqlCommandsNonQuery
{
    param
    (
    [System.Data.SqlClient.SqlConnection]$SqlConnection,
    [string[]]$Commands
    )
    $transaction = $SqlConnection.BeginTransaction()
    $command = $SqlConnection.CreateCommand()
    $command.Transaction = $transaction
    try
    {
        foreach($cmd in $Commands) {
            #Write-Host  $cmd -ForegroundColor Blue
            $command.CommandText = $cmd
            $command.ExecuteNonQuery()
        }
        $transaction.Commit()
        return $true
    }
    catch [Exception] {
         $transaction.Rollback()
         Write-Warning ('Execute Sql commands failed with error message:{0}' -f $_)
         return $false
    }
    finally{
        $SqlConnection.Close()
    }
}

#
# 暂停脚本
#
function Pause($Message = "Press any key to continue . . . ")
{
    if(-not (Test-Path Variable:psISE)) {
        Write-Host
        Write-Host -NoNewline $Message
        [void][System.Console]::ReadKey($true)
        Write-Host
    }
}