function Get-IcingaMemoryUsage()
{
    $MEMUsageInformations = Get-IcingaWindowsInformation Win32_OperatingSystem;

    [hashtable]$MEMUsageData = @{
        'FreePhysicalMemory'     = $MEMUsageInformations.FreePhysicalMemory;
        'FreeVirtualMemory'      = $MEMUsageInformations.FreeVirtualMemory;
        'TotalVirtualMemorySize' = $MEMUsageInformations.TotalVirtualMemorySize;
        'TotalVisibleMemorySize' = $MEMUsageInformations.TotalVisibleMemorySize;
        'MaxProcessMemorySize'   = $MEMUsageInformations.MaxProcessMemorySize;
    }

    return $MEMUsageData;
}
