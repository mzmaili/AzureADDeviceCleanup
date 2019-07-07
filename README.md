# AzureADDeviceCleanup
AzureADDeviceCleanup PowerShell script helps to manage the stale devices in Azure AD in an efficient way by giving different options to deal with stale devices in Azure AD.

Why is this script useful?
  - To check the stale devices in Azure AD.
  - To generate a powerful Excel report with the stale/disabled/deleted devices.
  - To automate Azure AD device cleanup procedure by running it in a scheduled task.
  - Can be used to disable the stale devices for a period of time, then clean them safely.
  - To show the result on Grid View or/and Excel, so you can easily search in the result.

What does this script do?
  - Verifies the stale devices as per the entered threshold days.
  - Disables the stale devices as per the entered threshold days.
  - Verifies the stale disabled devices as per the entered threshold days.
  - Cleans the stale devices from Azure AD as per the entered threshold days.
  - Cleans the stale disabled devices only from Azure AD as per the entered threshold days
  - Checks if ‘MSOnline‘ module is installed and updated. If not, it takes case of this.
  - Checks if ‘ImportExcel‘ module is installed. If not, it installs and imports it.
  
It is recommended to disable the stale devices for a grace period of time before deleting them from AAD safely, as you can not recover the deleted devices.

 

Using AzureADDeviceCleanup PowerShell script, you can automate Azure AD devices cleanup using schedule task as the following (ThresholdDays value can be changed as per the company's policy):

  - Disable all stale devices since 60 days using the PowerShell command:  
      AzureADDeviceCleanup.ps1 -ThresholdDays 60 -DisableDevices -SavedCreds

  - Then, Delete the stale disabled devices since 90 days using the PowerShell command:
      AzureADDeviceCleanup.ps1 -ThresholdDays 90 -CleanDisabledDevices -SavedCreds

 

Extremely Important Notes:
  - This source code is freeware and is provided on an "as is" basis without warranties of any kind, 
    whether express or implied, including without limitation warranties that the code is free of defect,
    fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of
    the code is with the end user.

  - It is not advisable to immediately delete a device that appears to be stale because you can't undo
    a deletion in the case of false positives. As a best practice, disable a device for a grace period 
    before deleting it. In your policy, define a timeframe to disable a device before deleting it. 

  - When configured, BitLocker keys for Windows 10 devices are stored on the device object in Azure AD. 
    If you delete a stale device, you also delete the BitLocker keys that are stored on the device. 
    You should determine whether your cleanup policy aligns with the actual lifecycle of your device 
    before deleting a stale device.
  - For more information, kindly visit the link:
    https://docs.microsoft.com/en-us/azure/active-directory/devices/manage-stale-devices

 
