<#
.SYNOPSIS
   Reads all available partition information and stores them inside a hashtable
   to assign drive leters properly to a disk and even to a a certain partition
.DESCRIPTION
   Reads all available partition information and stores them inside a hashtable
   to assign drive leters properly to a disk and even to a a certain partition
.FUNCTIONALITY
   Reads all available partition information and stores them inside a hashtable
   to assign drive leters properly to a disk and even to a a certain partition
.EXAMPLE
   PS>Get-IcingaDiskPartitionAssignment
.EXAMPLE
   PS>Get-IcingaDiskPartitionAssignment -DiskIds 0, 1
.PARAMETER DiskIds
   Allows to filter for certain disk ids. Siply provide the id itself like 0, 1
.OUTPUTS
   System.Hashtable
.LINK
   https://github.com/Icinga/icinga-powershell-framework
#>

function Get-IcingaPhysicalDiskInfo()
{
    param (
        [array]$DiskIds = @()
    );

    # Fetch all physical disks to work with
    $PhysicalDisks        = Get-IcingaWindowsInformation Win32_DiskDrive;

    # Fetch our disk info only for local disks and do not include network drives
    $LogicalDisk          = Get-IcingaWindowsInformation Win32_LogicalDisk -Filter 'DriveType = 3';
    $PartitionInformation = Get-IcingaDiskPartitionAssignment;
    $PhysicalDiskData     = @{ };

    foreach ($disk in $PhysicalDisks) {
        [string]$DiskId   = $disk.DeviceId.ToString().Replace('\\.\PHYSICALDRIVE', '');

        if ($DiskIds.Count -ne 0) {
            if (-Not ($DiskIds -Contains $DiskId)) {
                continue;
            }
        }

        $DiskData   = Get-IcingaDiskAttributes -DiskId $DiskId;
        $Partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClass Win32_DiskPartition;

        $DiskInfo = @{
            'ErrorCleared'                = $disk.ErrorCleared;
            'FirmwareRevision'            = $disk.FirmwareRevision;
            'Description'                 = $disk.Description;
            'PartitionStyle'              = ''; # Set later on partition check
            'PartitionLayout'             = @{};
            'DriveReference'              = $PartitionInformation[$DiskId].DriveLetters;
            'Caption'                     = $disk.Caption;
            'IsSystem'                    = $disk.IsSystem;
            'TotalHeads'                  = $disk.TotalHeads;
            'IsOffline'                   = ($DiskData.Offline);
            'MaxMediaSize'                = $disk.MaxMediaSize;
            'ConfigManagerUserConfig'     = $disk.ConfigManagerUserConfig;
            'Model'                       = $disk.Model;
            'BusType'                     = $disk.BusType;
            'PowerManagementCapabilities' = $disk.PowerManagementCapabilities;
            'TracksPerCylinder'           = $disk.TracksPerCylinder;
            'IsHighlyAvailable'           = $disk.IsHighlyAvailable;
            'DeviceID'                    = $disk.DeviceID;
            'NeedsCleaning'               = $disk.NeedsCleaning;
            'Index'                       = $disk.Index;
            'OperationalStatus'           = $disk.OperationalStatus;
            'MediaLoaded'                 = $disk.MediaLoaded;
            'LastErrorCode'               = $disk.LastErrorCode;
            'Size'                        = $disk.Size;
            'MinBlockSize'                = $disk.MinBlockSize;
            'IsScaleOut'                  = $disk.IsScaleOut;
            'InterfaceType'               = $disk.InterfaceType;
            'Capabilities'                = $disk.Capabilities;
            'PNPDeviceID'                 = $disk.PNPDeviceID;
            'Partitions'                  = $disk.Partitions;
            'SerialNumber'                = $disk.SerialNumber;
            'PowerManagementSupported'    = $disk.PowerManagementSupported;
            'ErrorMethodology'            = $disk.ErrorMethodology;
            'StatusInfo'                  = $disk.StatusInfo;
            'NumberOfMediaSupported'      = $disk.NumberOfMediaSupported;
            'InstallDate'                 = $disk.InstallDate;
            'DefaultBlockSize'            = $disk.DefaultBlockSize;
            'SystemCreationClassName'     = $disk.SystemCreationClassName;
            'SCSITargetId'                = $disk.SCSITargetId;
            'MediaType'                   = $disk.MediaType;
            'Availability'                = $disk.Availability;
            'BytesPerSector'              = $disk.BytesPerSector;
            'IsReadOnly'                  = $DiskData.ReadOnly;
            'Status'                      = $disk.Status;
            'SCSILogicalUnit'             = $disk.SCSILogicalUnit;
            'CapabilityDescriptions'      = $disk.CapabilityDescriptions;
            'SCSIPort'                    = $disk.SCSIPort;
            'TotalTracks'                 = $disk.TotalTracks;
            'CreationClassName'           = $disk.CreationClassName;
            'TotalCylinders'              = $disk.TotalCylinders;
            'HealthStatus'                = $disk.HealthStatus;
            'SCSIBus'                     = $disk.SCSIBus;
            'Signature'                   = $disk.Signature;
            'CompressionMethod'           = $disk.CompressionMethod;
            'TotalSectors'                = $disk.TotalSectors;
            'SystemName'                  = $disk.SystemName;
            'IsBoot'                      = $FALSE; #Always false here because we set the boot option later based on our partition config
            'MaxBlockSize'                = 0; # 0 because we later count the block size based on the amount of partitions
            'ErrorDescription'            = $disk.ErrorDescription;
            'Manufacturer'                = $disk.Manufacturer;
            'Name'                        = $disk.Name;
            'IsClustered'                 = $disk.IsClustered;
            'ConfigManagerErrorCode'      = $disk.ConfigManagerErrorCode;
            'SectorsPerTrack'             = $disk.SectorsPerTrack;
        }

        $MaxBlocks = 0;

        foreach ($partition in $Partitions) {
            $DriveLetter            = $null;
            $LogicalDisk            = $null;
            [string]$PartitionIndex = $partition.Index;

            if ($PartitionInformation.ContainsKey($DiskId) -And $PartitionInformation[$DiskId].Partitions.ContainsKey($PartitionIndex)) {
                $DriveLetter = $PartitionInformation[$DiskId].Partitions[$PartitionIndex];
                $LogicalDisk = Get-IcingaWindowsInformation Win32_LogicalDisk -Filter "DeviceId = '$DriveLetter'";
            }

            $DiskInfo.PartitionLayout.Add(
                $PartitionIndex,
                @{
                    'NumberOfBlocks'   = $Partition.NumberOfBlocks;
                    'BootPartition'    = $Partition.BootPartition;
                    'PrimaryPartition' = $Partition.PrimaryPartition;
                    'Size'             = $Partition.Size;
                    'Index'            = $Partition.Index;
                    'DiskIndex'        = $Partition.DiskIndex;
                    'DriveLetter'      = $DriveLetter;
                    'Bootable'         = $Partition.Bootable;
                    'Name'             = [string]::Format('Disk #{0}, Partition #{1}', $DiskId, $PartitionIndex);
                    'StartingOffset'   = $Partition.StartingOffset;
                    'Status'           = $Partition.Status;
                    'StatusInfo'       = $Partition.StatusInfo;
                    'Type'             = $Partition.Type;
                }
            )

            if ($null -ne $LogicalDisk) {
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'FreeSpace', $LogicalDisk.FreeSpace
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'VolumeName', $LogicalDisk.VolumeName
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'FileSystem', $LogicalDisk.FileSystem
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'VolumeSerialNumber', $LogicalDisk.VolumeSerialNumber
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'Description', $LogicalDisk.Description
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'Access', $LogicalDisk.Access
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'SupportsFileBasedCompression', $LogicalDisk.SupportsFileBasedCompression
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'SupportsDiskQuotas', $LogicalDisk.SupportsDiskQuotas
                );
                $DiskInfo.PartitionLayout[$PartitionIndex].Add(
                    'Compressed', $LogicalDisk.Compressed
                );
            }

            $MaxBlocks += $Partition.NumberOfBlocks;

            if ($Partition.Bootable) {
                $DiskInfo.IsBoot = $Partition.Bootable;
            }
            $DiskInfo.MaxBlockSize = $MaxBlocks;

            if ($Partition.Type -Like '*GPT*') {
                $DiskInfo.PartitionStyle = 'GPT';
            } else {
                $DiskInfo.PartitionStyle = 'MBR';
            }
        }

        $PhysicalDiskData.Add($DiskId, $diskinfo);
    }

    return $PhysicalDiskData;
}
