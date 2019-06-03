Param (
  [Parameter(Mandatory=$true)][string]$vCenterServerHost,
  [Parameter(Mandatory=$true)][string]$vCenterUsername,
  [Parameter(Mandatory=$true)][string]$vCenterPassword,
  [Parameter(Mandatory=$true)][string]$computeCluster,


  [Parameter(Mandatory=$true)][string]$vmName,
  [Parameter(Mandatory=$true)][string]$csrOvfPath,

  [Parameter(Mandatory=$true)][string]$hostname,
  [Parameter(Mandatory=$true)][string]$domainName,
  [Parameter(Mandatory=$true)][string]$username,
  [Parameter(Mandatory=$true)][string]$password,



  [Parameter(Mandatory=$true)][string]$mgmtIPCidr,
  [Parameter(Mandatory=$true)][string]$mgmtNetwork,
  [Parameter(Mandatory=$true)][string]$mgmtGateway,


  [Parameter(Mandatory=$true)][string]$gig1Portgroup,
  [Parameter(Mandatory=$true)][string]$gig2Portgroup,
  [Parameter(Mandatory=$true)][string]$gig3Portgroup
)

$date = Get-Date
$datestamp = -join($date.Year, "-", $date.Month, "-", $date.Day)

Connect-VIServer $vCenterServerHost -User $vCenterUsername -Password $vCenterPassword
$vcenter = $global:DefaultVIServer

if ($vcenter -eq $null) {
  Write-Host "Error connecting to vCenter"
  Write-Host $Error[0]
  Exit
}

# Get Cluster
$cluster = Get-Cluster -Name $computeCluster
# $resourcePoolGold = Get-ResourcePool -Name "Gold-Images"
# $resourcePool = Get-ResourcePool -Name $sandboxCode -Location $resourcePoolGold
# $vmFolder = Get-Folder -Name "sbx-$sandboxCode"

$vms = Get-VMHost -Location $cluster -State Connected
$vmhost = $vms[0]

$csrOvfConfig = Get-OvfConfiguration -Ovf $csrOvfPath

$csrConfigHash = $csrOvfConfig.ToHashTable()

$csrConfigHash["com.cisco.csr1000v.hostname.1"]=$hostname
$csrConfigHash["com.cisco.csr1000v.domain-name.1"]=$domainName
$csrConfigHash["com.cisco.csr1000v.login-username.1"]=$username
$csrConfigHash["com.cisco.csr1000v.login-password.1"]=$password
$csrConfigHash["com.cisco.csr1000v.privilege-password.1"]=$password

$csrConfigHash["com.cisco.csr1000v.mgmt-interface.1"]="GigabitEthernet1"
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-addr.1"]=$mgmtIPCidr
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-network.1"]=$mgmtNetwork
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-gateway.1"]=$mgmtGateway
$csrConfigHash["com.cisco.csr1000v.mgmt-vlan.1"]=""

$csrConfigHash["com.cisco.csr1000v.enable-ssh-server.1"]="True"
$csrConfigHash["com.cisco.csr1000v.enable-scp-server.1"]="True"

$csrConfigHash["com.cisco.csr1000v.resource-template.1"]="default"
$csrConfigHash["com.cisco.csr1000v.license.1"]="ax"

$csrConfigHash["com.cisco.csr1000v.pnsc-ipv4-addr.1"]=""
$csrConfigHash["com.cisco.csr1000v.remote-mgmt-ipv4-addr.1"]=""
$csrConfigHash["com.cisco.csr1000v.pnsc-agent-local-port.1"]=""
$csrConfigHash["com.cisco.csr1000v.pnsc-shared-secret-key.1"]=""

$csrConfigHash["NetworkMapping.GigabitEthernet1"]=$gig1Portgroup
$csrConfigHash["NetworkMapping.GigabitEthernet2"]=$gig2Portgroup
$csrConfigHash["NetworkMapping.GigabitEthernet3"]=$gig3Portgroup


Write-Host "Creating new VM from OVA $csrOvfPath named $vmName on PortGroup $portgroupname"
# $csr = Import-VApp $csrOvfPath -Name $vmName -OvfConfiguration $csrConfigHash -VMHost $vmhost -Location $resourcePool
$csr = Import-VApp $csrOvfPath -Name $vmName -OvfConfiguration $csrConfigHash -VMHost $vmhost

# Move-VM $csr -InventoryLocation $vmFolder
Set-VM $csr -NumCpu 4 -MemoryGB 8 -Confirm:$false

$notes = "Created On: $datestamp by $vCenterUsername
IP Address: $mgmtIPCidr
Username: $username
Password: $password"
$temp = Set-VM $csr -Confirm:$false -Notes $notes

Write-Host "VM Created, now starting it."
$temp = Start-VM $csr

# Waiting for 6 minutes until inital boot is complete and loads configuration
Write-Host "Waiting 6 minutes to allow the CSR to install and configure."
Start-Sleep -s 360
$temp = Wait-Tools -VM $csr


Write-Host "Deployment complete."
Disconnect-VIServer -Confirm:$false
