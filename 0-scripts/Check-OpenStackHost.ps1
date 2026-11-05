# Check-OpenStackHost.ps1 — vérification non destructive de l'hôte Windows et VirtualBox
# Usage: .\Check-OpenStackHost.ps1 -VMName 'openstack-aio-kolla'
[CmdletBinding()]
param([string]$VMName = 'openstack-aio-kolla')
$ErrorActionPreference = 'Stop'
$script:Warnings = 0
function Check([string]$Name, [bool]$Ok, [string]$Details, [bool]$Mandatory = $true) {
    if ($Ok) { Write-Host "[OK] $Name : $Details" -ForegroundColor Green }
    else {
        $label = if ($Mandatory) {'ATTENTION'} else {'INFO'}
        Write-Host "[$label] $Name : $Details" -ForegroundColor Yellow
        if ($Mandatory) { $script:Warnings++ }
    }
}
Write-Host "=== Contrôle Windows / VirtualBox / OpenStack : $VMName ===" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramGiB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$freeGiB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
Write-Host "Windows : $($os.Caption) ; CPU : $($cpu.Name) ; RAM : $ramGiB GiB (libre : $freeGiB GiB)"
Check 'Virtualisation activée dans le firmware' ($cpu.VirtualizationFirmwareEnabled -eq $true) "VirtualizationFirmwareEnabled=$($cpu.VirtualizationFirmwareEnabled)"
Check 'SLAT' ($cpu.SecondLevelAddressTranslationExtensions -eq $true) "SLAT=$($cpu.SecondLevelAddressTranslationExtensions)"
$bcd = (& bcdedit.exe /enum '{current}' 2>&1 | Out-String)
$mode = if ($bcd -match '(?im)^\s*hypervisorlaunchtype\s+(\w+)') { $Matches[1] } else { 'Non précisé (valeur par défaut possible)' }
$hv = [bool]$cs.HypervisorPresent
Check 'Mode VirtualBox natif (recommandé pour nested VT-x)' (($mode -eq 'Off') -and (-not $hv)) "BCD=$mode ; HypervisorPresent=$hv" $false
if ($hv) { Write-Host '  -> Hyperviseur Windows actif : VirtualBox peut fonctionner via WHP, mais nested VT-x peut être indisponible.' }
$vbs = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
if ($vbs) { Write-Host "VBS SecurityServicesRunning : $($vbs.SecurityServicesRunning -join ',') ; VirtualizationBasedSecurityStatus : $($vbs.VirtualizationBasedSecurityStatus)" }
$exe = @("$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe", 'VBoxManage.exe') | Where-Object { Test-Path $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
if (-not $exe) {
    $cmd = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($cmd) { $exe = $cmd.Source }
}
if (-not $exe) { Check 'VirtualBox' $false 'VBoxManage introuvable'; exit 2 }
Check 'VirtualBox' $true $exe
$info = & $exe showvminfo $VMName --machinereadable 2>&1
if ($LASTEXITCODE -ne 0) { Check 'VM VirtualBox' $false "VM '$VMName' introuvable"; exit 2 }
$props = @{}
foreach ($line in $info) {
    if ($line -match '^([^=]+)=(.*)$') { $props[$Matches[1]] = $Matches[2].Trim('"') }
}
$state = $props['VMState']
Write-Host "VM : $VMName ; état=$state ; vCPU=$($props['cpus']) ; RAM=$($props['memory']) MB"
Check 'Ressources VM' ([int]$props['cpus'] -ge 4 -and [int]$props['memory'] -ge 12288) 'Recommandé pour ce labo AIO : >= 4 vCPU et >= 12 Go RAM'
Check 'Mémoire disponible sur hôte' ($freeGiB -ge 3) "$freeGiB GiB libres à cet instant" $false
$nested = $props['nested-hw-virt']
if (-not $nested) { $nested = $props['NestedHWVirt'] }
Check 'Nested VT-x/AMD-V (nécessaire pour KVM dans Ubuntu)' ($nested -eq 'on') "nested-hw-virt=$nested" $false
$nicLines = $props.Keys | Where-Object { $_ -match '^(nic|hostonlyadapter|hostonlynet|cableconnected|nictype|nicpromisc)[1-8]$' } | Sort-Object
Write-Host 'Cartes réseau VirtualBox :'
foreach ($key in $nicLines) { Write-Host "  $key=$($props[$key])" }
Check 'NIC1 NAT' ($props['nic1'] -eq 'nat') "nic1=$($props['nic1'])"
Check 'NIC2 Host-Only' ($props['nic2'] -eq 'hostonly') "nic2=$($props['nic2'])"
Check 'NIC3 Host-Only' ($props['nic3'] -eq 'hostonly') "nic3=$($props['nic3'])"
if ($props['nicpromisc3']) { Check 'NIC3 mode promiscuité' ($props['nicpromisc3'] -eq 'allow-all') "nicpromisc3=$($props['nicpromisc3'])" $false }
Write-Host '\nCartes hôte VirtualBox (adresses IP) :'
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like '192.168.56.*' -or $_.IPAddress -like '192.168.57.*' } | Select-Object InterfaceAlias,IPAddress,PrefixLength | Format-Table -AutoSize
Write-Host '\nContrôles terminés. Points à examiner : ' $script:Warnings
Write-Host 'Aucune configuration Windows ou VirtualBox n’a été modifiée.'
