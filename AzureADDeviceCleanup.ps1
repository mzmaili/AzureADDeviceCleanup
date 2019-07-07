<# 

Extremely Important Notes:
=========================================================================================================
-   This source code is freeware and is provided on an "as is" basis without warranties of any kind, 
    whether express or implied, including without limitation warranties that the code is free of defect,
    fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of
    the code is with the end user.

-   It is not advisable to immediately delete a device that appears to be stale because you can't undo
    a deletion in the case of false positives. As a best practice, disable a device for a grace period 
    before deleting it. In your policy, define a timeframe to disable a device before deleting it. 

-   When configured, BitLocker keys for Windows 10 devices are stored on the device object in Azure AD. 
    If you delete a stale device, you also delete the BitLocker keys that are stored on the device. 
    You should determine whether your cleanup policy aligns with the actual lifecycle of your device 
    before deleting a stale device.

-   For more information, kindly visit the link:
    https://docs.microsoft.com/en-us/azure/active-directory/devices/manage-stale-devices
=========================================================================================================

 
.SYNOPSIS
    AzureADDeviceCleanup PowerShell script.

.DESCRIPTION
    AzureADDeviceCleanup.ps1 is a PowerShell script helps to manage the stale devices in Azure AD in an efficient way by giving different options to deal with stale devices in Azure AD tenants.

.AUTHOR:
    Mohammad Zmaili

.PARAMETER
    ThresholdDays
    Specifies the period of the last login.
    Note: The default value is 90 days if this parameter is not configured.

.PARAMETER
    Verify
    Verifies the affected devices that will be deleted when running the PowerShell with 'CleanDevices' parameter.

.PARAMETER
    VerifyDisabledDevices
    Verifies disabled devices that will be deleted when running the PowerShell with 'CleanDisabledDevices' parameter.

.PARAMETER
    DisableDevices
    Disables the stale devices as per the configured threshold.

.PARAMETER
    CleanDisabledDevices
    Removes the stale disabled devices as per the configured threshold.

.PARAMETER
    CleanDevices
    Removed the stale devices as per the configured threshold.

.PARAMETER
    OnScreenReport
    Displays The health check result on PowerShell screen.

.PARAMETER
    SavedCreds
    Uses the saved credentials option to connect to MSOnline.
    You can use any normal CLOUD only user who is having read permission to verify the devices. 
    But you have to use a global admin when using clean parameters.
    Notes: - This parameter is very helpful when automating/running the script in task schduler.
           - Update the saved credentials under the section "Update Saved credentials".


.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -Verify
    Verifies the stale devices since 90 says that will be deleted when running the PowerShell with 'CleanDevices' parameter.

.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -Verify -ThresholdDays <Number of Days>
    Verifies the stale devices as per the entered threshold days that will be deleted when running the PowerShell with 'CleanDevices' parameter.

.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -VerifyDisabledDevices -ThresholdDays <Number of Days>
    Verifies the DISABLED stale devices as per the entered threshold days that will be deleted when running the PowerShell with 'CleanDisabledDevices' parameter.

.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -VerifyDisabledDevices -ThresholdDays <Number of Days> -DisableDevices
    Disables the stale devices as per the entered threshold days.

.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -ThresholdDays <Number of Day> -CleanDevices -SavedCreds
    Removes the stale devices as per the entered threshold days, uses the saved credentials to access MSOnline.
    Note: You can automate running this script using task scheduler.

.EXAMPLE
    .\AzureADDeviceCleanup.ps1 -ThresholdDays <Number of Day> -CleanDisabledDevices -SavedCreds
    Removes the stale disabled devices as per the entered threshold days, uses the saved credentials to access MSOnline.
    Note: You can automate running this script using task scheduler.


Script Output:
-----------

===================================
|Azure AD Devices Cleanup Summary:|
===================================
Number of affected devices: 16
Last Login verified: 5/31/2019 2:32:37 PM
#>


[cmdletbinding()]
param(
        [Parameter( Mandatory=$false)]
        [Int]$ThresholdDays =90,

        [Parameter( Mandatory=$false)]
        [switch]$Verify,

        [Parameter( Mandatory=$false)]
        [switch]$VerifyDisabledDevices,

        [Parameter( Mandatory=$false)]
        [switch]$DisableDevices,
        
        [Parameter( Mandatory=$false)]
        [switch]$CleanDisabledDevices,

        [Parameter( Mandatory=$false)]
        [switch]$CleanDevices,
     
        [Parameter( Mandatory=$false)]
        [switch]$SavedCreds,

        [Parameter( Mandatory=$false)]
        [switch]$OnScreenReport

      )


#=========================
# Update Saved credentials
#=========================
$UserName = "user@domain.com"
$UserPass="PWD"
$UserPass=$UserPass|ConvertTo-SecureString -AsPlainText -Force
$UserCreds = New-Object System.Management.Automation.PsCredential($userName,$UserPass)


Function CheckInternet
{
$statuscode = (Invoke-WebRequest -Uri https://adminwebservice.microsoftonline.com/ProvisioningService.svc).statuscode
if ($statuscode -ne 200){
''
''
Write-Host "Operation aborted. Unable to connect to Azure AD, please check your internet connection." -ForegroundColor red -BackgroundColor Black
exit
}
}

Function CheckMSOnline{
''
Write-Host "Checking MSOnline Module..." -ForegroundColor Yellow
                            
    if (Get-Module -ListAvailable -Name MSOnline) {
        Import-Module MSOnline
        Write-Host "MSOnline Module has imported." -ForegroundColor Green -BackgroundColor Black
        ''

            Write-Host "Checking MSOnline version..." -ForegroundColor Yellow
            $MVersion = Get-Module msonline | Select-Object version
            if (($MVersion.Version.Major -eq 1) -and ($MVersion.Version.Minor -eq 1) -and ($MVersion.Version.Build -ge 183)){
                Write-Host "You have a supported version." -ForegroundColor Green -BackgroundColor Black
            }else{
                Write-Host "You have an old version." -ForegroundColor Red -BackgroundColor Black
                ''
                Write-Host "Updating MSOnline version..." -ForegroundColor Yellow
                Update-Module msonline -force
                Remove-Module msonline
                Import-Module msonline
                $MVersion = Get-Module msonline | Select-Object version
                if (($MVersion.Version.Major -eq 1) -and ($MVersion.Version.Minor -eq 1) -and ($MVersion.Version.Build -ge 183)){
                Write-Host "MSOnline Module has been updated. Please reopen PowerShell window." -ForegroundColor Green -BackgroundColor Black
                exit
                }else{
                Write-Host "Operation aborted. MSOnline module has not updated, please make sure you are running PowerShell as admin." -ForegroundColor red -BackgroundColor Black
                exit
                }

            }

        ''
        Write-Host "Connecting to MSOnline..." -ForegroundColor Yellow
        
        if ($SavedCreds){
            Connect-MsolService -Credential $UserCreds -ErrorAction SilentlyContinue
        }else{
            Connect-MsolService -ErrorAction SilentlyContinue
        }

        if (-not (Get-MsolCompanyInformation -ErrorAction SilentlyContinue)){
            Write-Host "Operation aborted. Unable to connect to MSOnline, please check you entered a correct credentials and you have the needed permissions." -ForegroundColor red -BackgroundColor Black
            exit
        }
        Write-Host "Connected to MSOnline successfully." -ForegroundColor Green -BackgroundColor Black
        ''
    } else {
        Write-Host "MSOnline Module is not installed." -ForegroundColor Red -BackgroundColor Black
        Write-Host "Installing MSOnline Module....." -ForegroundColor Yellow
        CheckInternet
        Install-Module MSOnline -force
                                
        if (Get-Module -ListAvailable -Name MSOnline) {                                
        Write-Host "MSOnline Module has installed." -ForegroundColor Green -BackgroundColor Black
        Import-Module MSOnline
        Write-Host "MSOnline Module has imported." -ForegroundColor Green -BackgroundColor Black
        ''
        Write-Host "Connecting to MSOnline..." -ForegroundColor Yellow
        Connect-MsolService -ErrorAction SilentlyContinue
        
        if (-not (Get-MsolCompanyInformation -ErrorAction SilentlyContinue)){
            Write-Host "Operation aborted. Unable to connect to MSOnline, please check you entered a correct credentials and you have the needed permissions." -ForegroundColor red -BackgroundColor Black
            exit
        }
        Write-Host "Connected to MSOnline successfully." -ForegroundColor Green -BackgroundColor Black
        ''
        } else {
        ''
        ''
        Write-Host "Operation aborted. MsOnline was not installed." -ForegroundColor red -BackgroundColor Black
        exit
        }
    }



}

Function CheckImportExcel{
Write-Host "Checking ImportExcel Module..." -ForegroundColor Yellow
                            
    if (Get-Module -ListAvailable -Name ImportExcel) {
        Import-Module ImportExcel
        Write-Host "ImportExcel Module has imported." -ForegroundColor Green -BackgroundColor Black
        ''
        ''
    } else {
        Write-Host "ImportExcel Module is not installed." -ForegroundColor Red -BackgroundColor Black
        ''
        Write-Host "Installing ImportExcel Module....." -ForegroundColor Yellow
        Install-Module ImportExcel -Force
                                
        if (Get-Module -ListAvailable -Name ImportExcel) {                                
        Write-Host "ImportExcel Module has installed." -ForegroundColor Green -BackgroundColor Black
        Import-Module ImportExcel
        Write-Host "ImportExcel Module has imported." -ForegroundColor Green -BackgroundColor Black
        ''
        ''
        } else {
        ''
        ''
        Write-Host "Operation aborted. ImportExcel was not installed." -ForegroundColor red -BackgroundColor Black
        exit
        }
    }



}


cls

'===================================================================================================='
Write-Host '                                      Azure AD Devices Cleanup                                    ' -ForegroundColor Green 
'===================================================================================================='
''                    
Write-Host "                                          IMPORTANT NOTES                                           " -ForegroundColor red 
Write-Host "===================================================================================================="
Write-Host "This source code is freeware and is provided on an 'as is' basis without warranties of any kind," -ForegroundColor yellow 
Write-Host "whether express or implied, including without limitation warranties that the code is free of defect," -ForegroundColor yellow 
Write-Host "fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of" -ForegroundColor yellow 
Write-Host "the code is with the end user." -ForegroundColor yellow 
''
Write-Host "It is not advisable to immediately delete a device that appears to be stale because you can't undo" -ForegroundColor yellow 
Write-Host "a deletion in the case of false positives. As a best practice, disable a device for a grace period " -ForegroundColor yellow 
Write-Host "before deleting it. In your policy, define a timeframe to disable a device before deleting it. " -ForegroundColor yellow 
''
Write-Host "When configured, BitLocker keys for Windows 10 devices are stored on the device object in Azure AD. " -ForegroundColor yellow 
Write-Host "If you delete a stale device, you also delete the BitLocker keys that are stored on the device. " -ForegroundColor yellow 
Write-Host "You should determine whether your cleanup policy aligns with the actual lifecycle of your device " -ForegroundColor yellow 
Write-Host "before deleting a stale device." -ForegroundColor yellow 
''
Write-Host "For more information, kindly visit the link:" -ForegroundColor yellow 
Write-Host "https://docs.microsoft.com/en-us/azure/active-directory/devices/manage-stale-devices" -ForegroundColor yellow 

"===================================================================================================="
''
CheckMSOnline

CheckImportExcel



$global:lastLogon = [datetime](get-date).AddDays(- $ThresholdDays)

$Date=("{0:s}" -f (get-date)).Split("T")[0] -replace "-", ""
$Time=("{0:s}" -f (get-date)).Split("T")[1] -replace ":", ""

$date2=("{0:s}" -f ($global:lastLogon)).Split("T")[0] -replace "-", ""

$workSheetName = "AADDevicesOlderthen-" + $date2


if ($Verify){
    Write-Host "Verifing stale devices older than"$global:lastLogon -ForegroundColor Yellow
    $filerep = "AzureADDevicesList_" + $Date + $Time + ".xlsx"  
    $rep=Get-MsolDevice -all -ReturnRegisteredOwners -LogonTimeBefore $global:lastLogon | select Enabled, ObjectId, DeviceId, DisplayName, DeviceOsType, DeviceOsVersion, DeviceTrustType, DeviceTrustLevel, ApproximateLastLogonTimestamp, DirSyncEnabled, LastDirSyncTime, @{Name=’Registeredowners’;Expression={[string]::join(“;”, ($_.Registeredowners))}}
    $rep | Export-Excel -workSheetName $workSheetName -path $filerep -ClearSheet -TableName "AADDevicesTable" -AutoSize
    $global:AffectedDevices = $rep.Count
    Write-Host "Verification Completed." -ForegroundColor Green -BackgroundColor Black
}elseif ($VerifyDisabledDevices){
    Write-Host "Verifing stale disabled devices older than"$global:lastLogon -ForegroundColor Yellow
    $filerep = "DisabledDevices_" + $Date + $Time + ".xlsx"  
    $rep=Get-MsolDevice -all -ReturnRegisteredOwners -LogonTimeBefore $global:lastLogon | where{$_.Enabled -eq $false} | select Enabled, ObjectId, DeviceId, DisplayName, DeviceOsType, DeviceOsVersion, DeviceTrustType, DeviceTrustLevel, ApproximateLastLogonTimestamp, DirSyncEnabled, LastDirSyncTime, @{Name=’Registeredowners’;Expression={[string]::join(“;”, ($_.Registeredowners))}} 
    $rep | Export-Excel -workSheetName $workSheetName -path $filerep -ClearSheet -TableName "AADDevicesTable" -AutoSize
    $global:AffectedDevices = $rep.Count
    Write-Host "Task Completed Successfully." -ForegroundColor Green -BackgroundColor Black
}elseif ($DisableDevices){
    Write-Host "Disabling stale devices older than"$global:lastLogon -ForegroundColor Yellow
    $filerep = "DisabledDevices_" + $Date + $Time + ".xlsx"  
    $rep=Get-MsolDevice -all -ReturnRegisteredOwners -LogonTimeBefore $global:lastLogon | where{$_.Enabled -eq $true} | select ObjectId, DeviceId, DisplayName, DeviceOsType, DeviceOsVersion, DeviceTrustType, DeviceTrustLevel, ApproximateLastLogonTimestamp, DirSyncEnabled, LastDirSyncTime, @{Name=’Registeredowners’;Expression={[string]::join(“;”, ($_.Registeredowners))}} 
    $rep | Disable-MsolDevice -Force
    $rep | Export-Excel -workSheetName $workSheetName -path $filerep -ClearSheet -TableName "AADDevicesTable" -AutoSize
    $global:AffectedDevices = $rep.Count
    Write-Host "Task Completed Successfully." -ForegroundColor Green -BackgroundColor Black
}elseif ($CleanDisabledDevices){
    Write-Host "Cleaning STALE DISABLED devices older than"$global:lastLogon -ForegroundColor Yellow
    $filerep = "CleanedDevices_" + $Date + $Time + ".xlsx"  
    $rep=Get-MsolDevice -all -ReturnRegisteredOwners -LogonTimeBefore $global:lastLogon | where{$_.Enabled -eq $false} | select ObjectId, DeviceId, DisplayName, DeviceOsType, DeviceOsVersion, DeviceTrustType, DeviceTrustLevel, ApproximateLastLogonTimestamp, DirSyncEnabled, LastDirSyncTime, @{Name=’Registeredowners’;Expression={[string]::join(“;”, ($_.Registeredowners))}} 
    $rep | Remove-MsolDevice -Force
    $rep | Export-Excel -workSheetName $workSheetName -path $filerep -ClearSheet -TableName "AADDevicesTable" -AutoSize
    $global:AffectedDevices = $rep.Count
    Write-Host "Task Completed Successfully." -ForegroundColor Green -BackgroundColor Black

}elseif ($CleanDevices){
    Write-Host "Cleaning STALE devices older than"$global:lastLogon -ForegroundColor Yellow
    $filerep = "CleanedDevices_" + $Date + $Time + ".xlsx"  
    $rep=Get-MsolDevice -all -ReturnRegisteredOwners -LogonTimeBefore $global:lastLogon | select ObjectId, DeviceId, DisplayName, DeviceOsType, DeviceOsVersion, DeviceTrustType, DeviceTrustLevel, ApproximateLastLogonTimestamp, DirSyncEnabled, LastDirSyncTime, @{Name=’Registeredowners’;Expression={[string]::join(“;”, ($_.Registeredowners))}} 
    $rep | Remove-MsolDevice -Force
    $rep | Export-Excel -workSheetName $workSheetName -path $filerep -ClearSheet -TableName "AADDevicesTable" -AutoSize
    $global:AffectedDevices = $rep.Count
    Write-Host "Task Completed Successfully." -ForegroundColor Green -BackgroundColor Black
}else{
    Write-Host "Operation aborted. You have not select any parameter, please make sure to select any of the following parameters:" -ForegroundColor red -BackgroundColor Black

    Write-Host "
Verify
Verifies the affected devices that will be deleted when running the PowerShell with 'CleanDevices' parameter.

VerifyDisabledDevices
Verifies disabled devices that will be deleted when running the PowerShell with 'CleanDisabledDevices' parameter.

DisableDevices
Disables the stale devices as per the configured threshold.

CleanDisabledDevices
Removes the stale disabled devices as per the configured threshold.

CleanDevices
Removed the stale devices as per the configured threshold.
" -ForegroundColor Yellow

    exit
}


if ($OnScreenReport) {
    $rep | Out-GridView -Title "Hybrid Devices Health Check Report"
}


''
''
Write-Host "==================================="
Write-Host "|Azure AD Devices Cleanup Summary:|"
Write-Host "==================================="
Write-Host "Number of affected devices:" $global:AffectedDevices
Write-Host "Last Login verified:" $global:lastLogon
''
$loc=Get-Location
Write-host $filerep "report has been created on the path:" $loc -ForegroundColor green -BackgroundColor Black
''