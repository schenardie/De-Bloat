<#
.SYNOPSIS
.Removes bloat from a fresh Windows build
.DESCRIPTION
.Removes AppX Packages
.Disables Cortana
.Removes McAfee
.Removes HP Bloat
.Removes Dell Bloat
.Removes Lenovo Bloat
.Windows 10 and Windows 11 Compatible
.Removes any unwanted installed applications
.Removes unwanted services and tasks
.Removes Edge Surf Game

.INPUTS
.OUTPUTS
C:\ProgramData\Debloat\Debloat.log
.NOTES
  Version:        4.2.5
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  08/03/2022
  Purpose/Change: Initial script development
  Change: 12/08/2022 - Added additional HP applications
  Change 23/09/2022 - Added Clipchamp (new in W11 22H2)
  Change 28/10/2022 - Fixed issue with Dell apps
  Change 23/11/2022 - Added Teams Machine wide to exceptions
  Change 27/11/2022 - Added Dell apps
  Change 07/12/2022 - Whitelisted Dell Audio and Firmware
  Change 19/12/2022 - Added Windows 11 start menu support
  Change 20/12/2022 - Removed Gaming Menu from Settings
  Change 18/01/2023 - Fixed Scheduled task error and cleared up $null posistioning
  Change 22/01/2023 - Re-enabled Telemetry for Endpoint Analytics
  Change 30/01/2023 - Added Microsoft Family to removal list
  Change 31/01/2023 - Fixed Dell loop
  Change 08/02/2023 - Fixed HP apps (thanks to http://gerryhampsoncm.blogspot.com/2023/02/remove-pre-installed-hp-software-during.html?m=1)
  Change 08/02/2023 - Removed reg keys for Teams Chat
  Change 14/02/2023 - Added HP Sure Apps
  Change 07/03/2023 - Enabled Location tracking (with commenting to disable)
  Change 08/03/2023 - Teams chat fix
  Change 10/03/2023 - Dell array fix
  Change 19/04/2023 - Added loop through all users for HKCU keys for post-OOBE deployments
  Change 29/04/2023 - Removes News Feed
  Change 26/05/2023 - Added Set-ACL
  Change 26/05/2023 - Added multi-language support for Set-ACL commands
  Change 30/05/2023 - Logic to check if gamepresencewriter exists before running Set-ACL to stop errors on re-run
  Change 25/07/2023 - Added Lenovo apps (Thanks to Simon Lilly and Philip Jorgensen)
  Change 31/07/2023 - Added LenovoAssist
  Change 21/09/2023 - Remove Windows backup for Win10
  Change 28/09/2023 - Enabled Diagnostic Tracking for Endpoint Analytics
  Change 02/10/2023 - Lenovo Fix
  Change 06/10/2023 - Teams chat fix
  Change 09/10/2023 - Dell Command Update change
  Change 11/10/2023 - Grab all uninstall strings and use native uninstaller instead of uninstall-package
  Change 14/10/2023 - Updated HP Audio package name
  Change 31/10/2023 - Added PowerAutomateDesktop and update Microsoft.Todos
  Change 01/11/2023 - Added fix for Windows backup removing Shell Components
  Change 06/11/2023 - Removes Windows CoPilot
  Change 07/11/2023 - HKU fix
  Change 13/11/2023 - Added CoPilot removal to .Default Users
  Change 14/11/2023 - Added logic to stop errors on HP machines without HP docs installed
  Change 14/11/2023 - Added logic to stop errors on Lenovo machines without some installers
  Change 15/11/2023 - Code Signed for additional security
  Change 02/12/2023 - Added extra logic before app uninstall to check if a user has logged in
  Change 04/01/2024 - Added Dropbox and DevHome to AppX removal
  Change 05/01/2024 - Added MSTSC to whitelist
  Change 25/01/2024 - Added logic for LenovoNow/LenovoWelcome
  Change 25/01/2024 - Updated Dell app list (thanks Hrvoje in comments)
  Change 29/01/2024 - Changed /I to /X in Dell command
  Change 30/01/2024 - Fix Lenovo Vantage version
  Change 31/01/2024 - McAfee fix and Dell changes
  Change 01/02/2024 - Dell fix
  Change 01/02/2024 - Added logic around appxremoval to stop failures in logging
  Change 05/02/2024 - Added whitelist parameters
  Change 16/02/2024 - Added wildcard to dropbox
  Change 23/02/2024 - Added Lenovo SmartMeetings
  Change 06/03/2024 - Added Lenovo View and Vantage
  Change 08/03/2024 - Added Lenovo Smart Noise Cancellation
N/A
#>

############################################################################################################
#                                         Initial Setup                                                    #
#                                                                                                          #
############################################################################################################
param (
    [string[]]$customwhitelist
)

##Elevate if needed

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host "                                               3"
    Start-Sleep 1
    Write-Host "                                               2"
    Start-Sleep 1
    Write-Host "                                               1"
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -WhitelistApps {1}" -f $PSCommandPath, ($WhitelistApps -join ',')) -Verb RunAs
    Exit
}

#no errors throughout
$ErrorActionPreference = 'silentlycontinue'


#Create Folder
$DebloatFolder = "C:\ProgramData\Debloat"
If (Test-Path $DebloatFolder) {
    Write-Output "$DebloatFolder exists. Skipping."
}
Else {
    Write-Output "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$DebloatFolder" -ItemType Directory
    Write-Output "The folder $DebloatFolder was successfully created."
}

Start-Transcript -Path "C:\ProgramData\Debloat\Debloat.log"

$locale = Get-WinSystemLocale | Select-Object -expandproperty Name

##Switch on locale to set variables
## Switch on locale to set variables
switch ($locale) {
    "ar-SA" {
        $everyone = "الجميع"
        $builtin = "مدمج"
    }
    "bg-BG" {
        $everyone = "Всички"
        $builtin = "Вграден"
    }
    "cs-CZ" {
        $everyone = "Všichni"
        $builtin = "Vestavěný"
    }
    "da-DK" {
        $everyone = "Alle"
        $builtin = "Indbygget"
    }
    "de-DE" {
        $everyone = "Jeder"
        $builtin = "Integriert"
    }
    "el-GR" {
        $everyone = "Όλοι"
        $builtin = "Ενσωματωμένο"
    }
    "en-US" {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }    
    "en-GB" {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }
    "es-ES" {
        $everyone = "Todos"
        $builtin = "Incorporado"
    }
    "et-EE" {
        $everyone = "Kõik"
        $builtin = "Sisseehitatud"
    }
    "fi-FI" {
        $everyone = "Kaikki"
        $builtin = "Sisäänrakennettu"
    }
    "fr-FR" {
        $everyone = "Tout le monde"
        $builtin = "Intégré"
    }
    "he-IL" {
        $everyone = "כולם"
        $builtin = "מובנה"
    }
    "hr-HR" {
        $everyone = "Svi"
        $builtin = "Ugrađeni"
    }
    "hu-HU" {
        $everyone = "Mindenki"
        $builtin = "Beépített"
    }
    "it-IT" {
        $everyone = "Tutti"
        $builtin = "Incorporato"
    }
    "ja-JP" {
        $everyone = "すべてのユーザー"
        $builtin = "ビルトイン"
    }
    "ko-KR" {
        $everyone = "모든 사용자"
        $builtin = "기본 제공"
    }
    "lt-LT" {
        $everyone = "Visi"
        $builtin = "Įmontuotas"
    }
    "lv-LV" {
        $everyone = "Visi"
        $builtin = "Iebūvēts"
    }
    "nb-NO" {
        $everyone = "Alle"
        $builtin = "Innebygd"
    }
    "nl-NL" {
        $everyone = "Iedereen"
        $builtin = "Ingebouwd"
    }
    "pl-PL" {
        $everyone = "Wszyscy"
        $builtin = "Wbudowany"
    }
    "pt-BR" {
        $everyone = "Todos"
        $builtin = "Integrado"
    }
    "pt-PT" {
        $everyone = "Todos"
        $builtin = "Incorporado"
    }
    "ro-RO" {
        $everyone = "Toată lumea"
        $builtin = "Incorporat"
    }
    "ru-RU" {
        $everyone = "Все пользователи"
        $builtin = "Встроенный"
    }
    "sk-SK" {
        $everyone = "Všetci"
        $builtin = "Vstavaný"
    }
    "sl-SI" {
        $everyone = "Vsi"
        $builtin = "Vgrajen"
    }
    "sr-Latn-RS" {
        $everyone = "Svi"
        $builtin = "Ugrađeni"
    }
    "sv-SE" {
        $everyone = "Alla"
        $builtin = "Inbyggd"
    }
    "th-TH" {
        $everyone = "ทุกคน"
        $builtin = "ภายในเครื่อง"
    }
    "tr-TR" {
        $everyone = "Herkes"
        $builtin = "Yerleşik"
    }
    "uk-UA" {
        $everyone = "Всі"
        $builtin = "Вбудований"
    }
    "zh-CN" {
        $everyone = "所有人"
        $builtin = "内置"
    }
    "zh-TW" {
        $everyone = "所有人"
        $builtin = "內建"
    }
    default {
        $everyone = "Everyone"
        $builtin = "Builtin"
    }
}

############################################################################################################
#                                       Grab all Uninstall Strings                                         #
#                                                                                                          #
############################################################################################################


write-host "Checking 32-bit System Registry"
##Search for 32-bit versions and list them
$allstring = @()
$path1 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($32app in $32apps) {
    #Get uninstall string
    $string1 = $32app.uninstallstring
    #Check if it's an MSI install
    if ($string1 -match "^msiexec*") {
        #MSI install, replace the I with an X and make it quiet
        $string2 = $string1 + " /quiet /norestart"
        $string2 = $string2 -replace "/I", "/X "
        #Create custom object with name and string
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $32app.DisplayName
            String = $string2
        }
    }
    else {
        #Exe installer, run straight path
        $string2 = $string1
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $32app.DisplayName
            String = $string2
        }
    }

}
write-host "32-bit check complete"
write-host "Checking 64-bit System registry"
##Search for 64-bit versions and list them

$path2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($64app in $64apps) {
    #Get uninstall string
    $string1 = $64app.uninstallstring
    #Check if it's an MSI install
    if ($string1 -match "^msiexec*") {
        #MSI install, replace the I with an X and make it quiet
        $string2 = $string1 + " /quiet /norestart"
        $string2 = $string2 -replace "/I", "/X "
        #Uninstall with string2 params
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $64app.DisplayName
            String = $string2
        }
    }
    else {
        #Exe installer, run straight path
        $string2 = $string1
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $64app.DisplayName
            String = $string2
        }
    }

}

write-host "64-bit checks complete"

##USER
write-host "Checking 32-bit User Registry"
##Search for 32-bit versions and list them
$path1 = "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
##Check if path exists
if (Test-Path $path1) {
    #Loop Through the apps if name has Adobe and NOT reader
    $32apps = Get-ChildItem -Path $path1 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

    foreach ($32app in $32apps) {
        #Get uninstall string
        $string1 = $32app.uninstallstring
        #Check if it's an MSI install
        if ($string1 -match "^msiexec*") {
            #MSI install, replace the I with an X and make it quiet
            $string2 = $string1 + " /quiet /norestart"
            $string2 = $string2 -replace "/I", "/X "
            #Create custom object with name and string
            $allstring += New-Object -TypeName PSObject -Property @{
                Name   = $32app.DisplayName
                String = $string2
            }
        }
        else {
            #Exe installer, run straight path
            $string2 = $string1
            $allstring += New-Object -TypeName PSObject -Property @{
                Name   = $32app.DisplayName
                String = $string2
            }
        }
    }
}
write-host "32-bit check complete"
write-host "Checking 64-bit Use registry"
##Search for 64-bit versions and list them

$path2 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
#Loop Through the apps if name has Adobe and NOT reader
$64apps = Get-ChildItem -Path $path2 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString

foreach ($64app in $64apps) {
    #Get uninstall string
    $string1 = $64app.uninstallstring
    #Check if it's an MSI install
    if ($string1 -match "^msiexec*") {
        #MSI install, replace the I with an X and make it quiet
        $string2 = $string1 + " /quiet /norestart"
        $string2 = $string2 -replace "/I", "/X "
        #Uninstall with string2 params
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $64app.DisplayName
            String = $string2
        }
    }
    else {
        #Exe installer, run straight path
        $string2 = $string1
        $allstring += New-Object -TypeName PSObject -Property @{
            Name   = $64app.DisplayName
            String = $string2
        }
    }

}

############################################################################################################
#                                        Remove Manufacturer Bloat                                         #
#                                                                                                          #
############################################################################################################
##Check Manufacturer
write-host "Detecting Manufacturer"
$details = Get-CimInstance -ClassName Win32_ComputerSystem
$manufacturer = $details.Manufacturer

if ($manufacturer -like "*HP*") {
    Write-Host "HP detected"
    #Remove HP bloat


    ##HP Specific
    $UninstallPrograms = @(
        "HP Client Security Manager"
        "HP Notifications"
        "HP Security Update Service"
        "HP System Default Settings"
        "HP Wolf Security"
        "HP Wolf Security Application Support for Sure Sense"
        "HP Wolf Security Application Support for Windows"
        "AD2F1837.HPPCHardwareDiagnosticsWindows"
        "AD2F1837.HPPowerManager"
        "AD2F1837.HPPrivacySettings"
        "AD2F1837.HPQuickDrop"
        "AD2F1837.HPSupportAssistant"
        "AD2F1837.HPSystemInformation"
        "AD2F1837.myHP"
        "RealtekSemiconductorCorp.HPAudioControl",
        "HP Sure Recover",
        "HP Sure Run Module"
        "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj"
    )

    ##If custom whitelist specified, remove from array
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
        $UninstallPrograms = $UninstallPrograms | Where-Object { $customWhitelistApps -notcontains $_ }
    }

    $WhitelistedApps = @(
    )

    ##Add custom whitelist apps
    ##If custom whitelist specified, remove from array
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
        foreach ($customwhitelistapp in $customwhitelistapps) {
            $WhitelistedApps += $customwhitelistapp
        }        
    }

    $HPidentifier = "AD2F1837"

    $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { (($UninstallPackages -contains $_.Name) -or ($_.Name -match "^$HPidentifier")) -and ($_.Name -NotMatch $WhitelistedApps) }

    $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { (($UninstallPackages -contains $_.Name) -or ($_.Name -match "^$HPidentifier")) -and ($_.Name -NotMatch $WhitelistedApps) }

    $InstalledPrograms = $allstring | Where-Object { $UninstallPrograms -contains $_.Name }

    # Remove provisioned packages first
    ForEach ($ProvPackage in $ProvisionedPackages) {

        Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

        Try {
            $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
            Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
        }
        Catch { Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]" }
    }

    # Remove appx packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                            
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

        Try {
            $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
    }

    # Remove installed programs
    $InstalledPrograms | ForEach-Object {

        Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
        $uninstallcommand = $_.String

        Try {
            if ($uninstallcommand -match "^msiexec*") {
                #Remove msiexec as we need to split for the uninstall
                $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                #Uninstall with string2 params
                Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
                #Exe installer, run straight path
                $string2 = $uninstallcommand
                start-process $string2
            }
            #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode
            #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
            Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
        }
        Catch { Write-Warning -Message "Failed to uninstall: [$($_.Name)]" }


    }

    ##Belt and braces, remove via CIM too
    foreach ($program in $UninstallPrograms) {
        Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }


    #Remove HP Documentation if it exists
    if (test-path -Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd") {
        $A = Start-Process -FilePath "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -Wait -passthru -NoNewWindow
    }

    ##Remove HP Connect Optimizer if setup.exe exists
    if (test-path -Path 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe') {
        invoke-webrequest -uri "https://raw.githubusercontent.com/schenardie/public/main/De-Bloat/HPConnOpt.iss" -outfile "C:\Windows\Temp\HPConnOpt.iss"

        &'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe' @('-s', '-f1C:\Windows\Temp\HPConnOpt.iss')
    }
    Write-Host "Removed HP bloat"
}



if ($manufacturer -like "*Dell*") {
    Write-Host "Dell detected"
    #Remove Dell bloat

    ##Dell

    $UninstallPrograms = @(
        "Dell Optimizer"
        "Dell Power Manager"
        "DellOptimizerUI"
        "Dell SupportAssist OS Recovery"
        "Dell SupportAssist"
        "Dell Optimizer Service"
        "Dell Optimizer Core"
        "DellInc.PartnerPromo"
        "DellInc.DellOptimizer"
        "DellInc.DellCommandUpdate"
        "DellInc.DellPowerManager"
        "DellInc.DellDigitalDelivery"
        "DellInc.DellSupportAssistforPCs"
        "DellInc.PartnerPromo"
        "Dell Command | Update"
        "Dell Command | Update for Windows Universal"
        "Dell Command | Update for Windows 10"
        "Dell Command | Power Manager"
        "Dell Digital Delivery Service"
        "Dell Digital Delivery"
        "Dell Peripheral Manager"
        "Dell Power Manager Service"
        "Dell SupportAssist Remediation"
        "SupportAssist Recovery Assistant"
        "Dell SupportAssist OS Recovery Plugin for Dell Update"
        "Dell SupportAssistAgent"
        "Dell Update - SupportAssist Update Plugin"
        "Dell Core Services"
        "Dell Pair"
        "Dell Display Manager 2.0"
        "Dell Display Manager 2.1"
        "Dell Display Manager 2.2"
        "Dell SupportAssist Remediation"
        "Dell Update - SupportAssist Update Plugin"
        "DellInc.PartnerPromo"
    )



    $WhitelistedApps = @(
        "WavesAudio.MaxxAudioProforDell2019"
        "Dell - Extension*"
        "Dell, Inc. - Firmware*"
    )

    ##Add custom whitelist apps
    ##If custom whitelist specified, remove from array
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
        foreach ($customwhitelistapp in $customwhitelistapps) {
            $WhitelistedApps += $customwhitelistapp
        }        
    }

    $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { (($_.Name -in $UninstallPrograms) -or ($_.Name -like "*Dell*")) -and ($_.Name -NotMatch $WhitelistedApps) }

    $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { (($_.Name -in $UninstallPrograms) -or ($_.Name -like "*Dell*")) -and ($_.Name -NotMatch $WhitelistedApps) }

    $InstalledPrograms = $allstring | Where-Object { (($_.Name -in $UninstallPrograms) -or ($_.Name -like "*Dell*")) -and ($_.Name -NotMatch $WhitelistedApps) }
    # Remove provisioned packages first
    ForEach ($ProvPackage in $ProvisionedPackages) {

        Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

        Try {
            $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
            Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
        }
        Catch { Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]" }
    }

    # Remove appx packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                            
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

        Try {
            $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
    }

    # Remove any bundled packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                            
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

        Try {
            $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
    }


    # Remove installed programs
    $InstalledPrograms | ForEach-Object {

        Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
        $uninstallcommand = $_.String

        Try {
            if ($uninstallcommand -match "^msiexec*") {
                #Remove msiexec as we need to split for the uninstall
                $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                $uninstallcommand = $uninstallcommand + " /quiet /norestart"
                $uninstallcommand = $uninstallcommand -replace "/I", "/X "   
                #Uninstall with string2 params
                Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
                #Exe installer, run straight path
                $string2 = $uninstallcommand
                start-process $string2
            }
            #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode        
            #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
            Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
        }
        Catch { Write-Warning -Message "Failed to uninstall: [$($_.Name)]" }
    }

    ##Belt and braces, remove via CIM too
    foreach ($program in $UninstallPrograms) {
        Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }

    ##Manual Removals

    ##Dell Optimizer
    $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer*Core" } | Select-Object -Property UninstallString
 
    ForEach ($sa in $dellSA) {
        If ($sa.UninstallString) {
            cmd.exe /c $sa.UninstallString /quiet /norestart
        }
    }

    ##Dell Dell SupportAssist OS Recovery Plugin for Dell Update
    $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "SupportAssist" } | Select-Object -Property UninstallString
 
    ForEach ($sa in $dellSA) {
        If ($sa.UninstallString) {
            cmd.exe /c $sa.UninstallString /quiet /norestart
        }
    }

    ##Dell Dell SupportAssist Remediation
    $uninstallcommand = "/X {C4543FDB-3BC0-4585-B1C5-258FB7C2EA71} /qn"
    Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait

}


if ($manufacturer -like "Lenovo") {
    Write-Host "Lenovo detected"

    #Remove HP bloat

    ##Lenovo Specific
    # Function to uninstall applications with .exe uninstall strings

    function UninstallApp {

        param (
            [string]$appName
        )

        # Get a list of installed applications from Programs and Features
        $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName -like "*$appName*" }

        # Loop through the list of installed applications and uninstall them

        foreach ($app in $installedApps) {
            $uninstallString = $app.UninstallString
            $displayName = $app.DisplayName
            Write-Host "Uninstalling: $displayName"
            Start-Process $uninstallString -ArgumentList "/VERYSILENT" -Wait
            Write-Host "Uninstalled: $displayName" -ForegroundColor Green
        }
    }

    ##Stop Running Processes

    $processnames = @(
        "SmartAppearanceSVC.exe"
        "UDClientService.exe"
        "ModuleCoreService.exe"
        "ProtectedModuleHost.exe"
        "*lenovo*"
        "FaceBeautify.exe"
        "McCSPServiceHost.exe"
        "mcapexe.exe"
        "MfeAVSvc.exe"
        "mcshield.exe"
        "Ammbkproc.exe"
        "AIMeetingManager.exe"
        "DADUpdater.exe"
        "CommercialVantage.exe"
    )

    foreach ($process in $processnames) {
        write-host "Stopping Process $process"
        Get-Process -Name $process | Stop-Process -Force
        write-host "Process $process Stopped"
    }

    $UninstallPrograms = @(
        "E046963F.AIMeetingManager"
        "E0469640.SmartAppearance"
        "MirametrixInc.GlancebyMirametrix"
        "E046963F.LenovoCompanion"
        "E0469640.LenovoUtility"
        "E0469640.LenovoSmartCommunication"
        "E046963F.LenovoSettingsforEnterprise"
        "E046963F.cameraSettings"
        "4505Fortemedia.FMAPOControl2_2.1.37.0_x64__4pejv7q2gmsnr"
        "ElevocTechnologyCo.Ltd.SmartMicrophoneSettings_1.1.49.0_x64__ttaqwwhyt5s6t"
    )

    ##If custom whitelist specified, remove from array
    if ($customwhitelist) {
        $customWhitelistApps = $customwhitelist -split ","
        $UninstallPrograms = $UninstallPrograms | Where-Object { $customWhitelistApps -notcontains $_ }
    }
    
    
    $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { (($_.Name -in $UninstallPrograms)) }
    
    $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { (($_.Name -in $UninstallPrograms)) }
    
    $InstalledPrograms = $allstring | Where-Object { (($_.Name -in $UninstallPrograms)) }
    # Remove provisioned packages first
    ForEach ($ProvPackage in $ProvisionedPackages) {
    
        Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
    
        Try {
            $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
            Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
        }
        Catch { Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]" }
    }
    
    # Remove appx packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                                
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    
        Try {
            $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
    }
    
    # Remove any bundled packages
    ForEach ($AppxPackage in $InstalledPackages) {
                                                
        Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    
        Try {
            $null = Get-AppxPackage -AllUsers -PackageTypeFilter Main, Bundle, Resource -Name $AppxPackage.Name | Remove-AppxPackage -AllUsers
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
        Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
    }
    
    
    # Remove installed programs
    $InstalledPrograms | ForEach-Object {

        Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
        $uninstallcommand = $_.String

        Try {
            if ($uninstallcommand -match "^msiexec*") {
                #Remove msiexec as we need to split for the uninstall
                $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                #Uninstall with string2 params
                Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
                #Exe installer, run straight path
                $string2 = $uninstallcommand
                start-process $string2
            }
            #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode
            #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
            Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
        }
        Catch { Write-Warning -Message "Failed to uninstall: [$($_.Name)]" }
    }

    ##Belt and braces, remove via CIM too
    foreach ($program in $UninstallPrograms) {
        Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }

    # Get Lenovo Vantage service uninstall string to uninstall service
    $lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -eq "Lenovo Vantage Service"
    if (!([string]::IsNullOrEmpty($lvs.QuietUninstallString))) {
        $uninstall = "cmd /c " + $lvs.QuietUninstallString
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }

    # Uninstall Lenovo Smart
    UninstallApp -appName "Lenovo Smart"

    # Uninstall Ai Meeting Manager Service
    UninstallApp -appName "Ai Meeting Manager"

    # Uninstall ImController service
    ##Check if exists
    $path = "c:\windows\system32\ImController.InfInstaller.exe"
    if (Test-Path $path) {
        Write-Host "ImController.InfInstaller.exe exists"
        $uninstall = "cmd /c " + $path + " -uninstall"
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }
    else {
        Write-Host "ImController.InfInstaller.exe does not exist"
    }
    ##Invoke-Expression -Command 'cmd.exe /c "c:\windows\system32\ImController.InfInstaller.exe" -uninstall'

    # Remove vantage associated registry keys
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue
    #Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Commercial Vantage' -Recurse -ErrorAction SilentlyContinue

    # Uninstall AI Meeting Manager Service
    $path = 'C:\Program Files\Lenovo\Ai Meeting Manager Service\unins000.exe'
    $params = "/SILENT"
    if (test-path -Path $path) {
        Start-Process -FilePath $path -ArgumentList $params -Wait
    }
    # Uninstall Lenovo Vantage
    $pathname = (Get-ChildItem -Path "C:\Program Files (x86)\Lenovo\VantageService").name
    $path = "C:\Program Files (x86)\Lenovo\VantageService\$pathname\Uninstall.exe"
    $params = '/SILENT'
    if (test-path -Path $path) {
        Start-Process -FilePath $path -ArgumentList $params -Wait
    }
 
    ##Uninstall Smart Appearance
    $path = 'C:\Program Files\Lenovo\Lenovo Smart Appearance Components\unins000.exe'
    $params = '/SILENT'
    if (test-path -Path $path) {
        Start-Process -FilePath $path -ArgumentList $params -Wait
    }
    $lenovowelcome = "c:\program files (x86)\lenovo\lenovowelcome\x86"
    if (Test-Path $lenovowelcome) {
        # Remove Lenovo Now
        Set-Location "c:\program files (x86)\lenovo\lenovowelcome\x86"

        # Update $PSScriptRoot with the new working directory
        $PSScriptRoot = (Get-Item -Path ".\").FullName
        invoke-expression -command .\uninstall.ps1

        Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
    }

    $lenovonow = "c:\program files (x86)\lenovo\LenovoNow\x86"
    if (Test-Path $lenovonow) {
        # Remove Lenovo Now
        Set-Location "c:\program files (x86)\lenovo\LenovoNow\x86"

        # Update $PSScriptRoot with the new working directory
        $PSScriptRoot = (Get-Item -Path ".\").FullName
        invoke-expression -command .\uninstall.ps1

        Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
    }
}


############################################################################################################
#                                        Remove Any other installed crap                                   #
#                                                                                                          #
############################################################################################################

#McAfee

write-host "Detecting McAfee"
$mcafeeinstalled = "false"
$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach ($obj in $InstalledSoftware) {
    $name = $obj.GetValue('DisplayName')
    if ($name -like "*McAfee*") {
        $mcafeeinstalled = "true"
    }
}

$InstalledSoftware32 = Get-ChildItem "HKLM:\Software\WOW6432NODE\Microsoft\Windows\CurrentVersion\Uninstall"
foreach ($obj32 in $InstalledSoftware32) {
    $name32 = $obj32.GetValue('DisplayName')
    if ($name32 -like "*McAfee*") {
        $mcafeeinstalled = "true"
    }
}

if ($mcafeeinstalled -eq "true") {
    Write-Host "McAfee detected"
    #Remove McAfee bloat
    ##McAfee
    ### Download McAfee Consumer Product Removal Tool ###
    write-host "Downloading McAfee Removal Tool"
    # Download Source
    $URL = 'https://github.com/schenardie/public/raw/main/De-Bloat/mcafeeclean.zip'

    # Set Save Directory
    $destination = 'C:\ProgramData\Debloat\mcafee.zip'

    #Download the file
    Invoke-WebRequest -Uri $URL -OutFile $destination -Method Get
  
    Expand-Archive $destination -DestinationPath "C:\ProgramData\Debloat" -Force

    write-host "Removing McAfee"
    # Automate Removal and kill services
    start-process "C:\ProgramData\Debloat\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"
    write-host "McAfee Removal Tool has been run"

    $InstalledPrograms = $allstring | Where-Object { ($_.Name -like "*McAfee*") }
    $InstalledPrograms | ForEach-Object {

        Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
        $uninstallcommand = $_.String

        Try {
            if ($uninstallcommand -match "^msiexec*") {
                #Remove msiexec as we need to split for the uninstall
                $uninstallcommand = $uninstallcommand -replace "msiexec.exe", ""
                $uninstallcommand = $uninstallcommand + " /quiet /norestart"
                $uninstallcommand = $uninstallcommand -replace "/I", "/X "   
                #Uninstall with string2 params
                Start-Process 'msiexec.exe' -ArgumentList $uninstallcommand -NoNewWindow -Wait
            }
            else {
                #Exe installer, run straight path
                $string2 = $uninstallcommand
                start-process $string2
            }
            #$A = Start-Process -FilePath $uninstallcommand -Wait -passthru -NoNewWindow;$a.ExitCode        
            #$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
            Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
        }
        Catch { Write-Warning -Message "Failed to uninstall: [$($_.Name)]" }
    }

    ##Remove Safeconnect
    $safeconnects = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "McAfee Safe Connect" } | Select-Object -Property UninstallString
 
    ForEach ($sc in $safeconnects) {
        If ($sc.UninstallString) {
            cmd.exe /c $sc.UninstallString /quiet /norestart
        }
    }
}

write-host "Completed"

Stop-Transcript
