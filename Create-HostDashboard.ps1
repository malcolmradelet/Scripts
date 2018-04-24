Function Initialize-Dashboard {
    Start-UDDashboard -Content { 
        New-UDDashboard -Title "$env:computername - Dashboard" -Content {
            New-UDLayout -Columns 3 -Content {
                New-UDTable -Title "Server Information" -Headers @(" ", " ") -Endpoint {
                    @{
                        'Computer Name' = $env:COMPUTERNAME
                        'Operating System' = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                        'Build number' = (Get-CimInstance Win32_OperatingSystem).version
                        'Total Disk Space (C:)' = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
                        'Free Disk Space (C:)' = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB | ForEach-Object { "$([Math]::Round($_, 2)) GBs " }
                    }.GetEnumerator() | Out-UDTableData -Property @("Name", "Value")
                }
                New-UdMonitor -Title "CPU (% processor time)" -Type Line -DataPointHistory 20 -RefreshInterval 5 -ChartBackgroundColor '#80FF6B63' -ChartBorderColor '#FFFF6B63'  -Endpoint {
                    Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue | Out-UDMonitorData
                }
                New-UdChart -Title "Disk Space by Drive" -Type Bar -AutoRefresh -Endpoint {
                    Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
                        [PSCustomObject]@{ DeviceId = $_.DeviceID;
                            Size = [Math]::Round($_.Size / 1GB, 2);
                            FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2); 
                        } } | Out-UDChartData -LabelProperty "DeviceID" -Dataset @(
                        New-UdChartDataset -DataProperty "Size" -Label "Size" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
                        New-UdChartDataset -DataProperty "FreeSpace" -Label "Free Space" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
                    )
                }
                New-UDMonitor -Title "Downloads per second" -Type Line -DataPointHistory 20 -RefreshInterval 1 -Endpoint {
                    Get-Random -Minimum 25 -Maximum 100 | Out-UDMonitorData
                }
                New-UDInput -Title "Module Info Locator" -Endpoint {
                    param($ModuleName) 
            
                    # Get a module from the gallery
                    $Module = Find-Module $ModuleName
            
                    # Output a new card based on that info
                    New-UDInputAction -Content @(
                        New-UDCard -Title "$ModuleName - $($Module.Version)" -Text $Module.Description
                    )
                }
                New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint {
                    Get-Process | Out-UDGridData
                } -PageSize 2
            }
        } -Theme (Get-UDTheme -Name "Azure")
    } -Port 8080
}

Get-UDDashboard | Stop-UDDashboard