Param (
  [Parameter(Mandatory=$true,
             HelpMessage="vCenter IP or FQDN")][string]$vCenterServerHost,
  [Parameter(Mandatory=$true,
             HelpMessage="vCenter User Account")][string]$vCenterUsername,
  [Parameter(Mandatory=$true,
             HelpMessage="vCenter User Password")][string]$vCenterPassword,


  [Parameter(Mandatory=$true,
             HelpMessage="vCenter Compute Cluster to deploy CSR onto.")][string]$computeCluster,


  [Parameter(Mandatory=$true,
             HelpMessage="Name of the VM in vCenter")][string]$vmName,
  [Parameter(Mandatory=$true,
             HelpMessage="Location of CSR OVA file to deploy.")][string]$csrOvfPath,

  [Parameter(Mandatory=$false,
             HelpMessage="CSR Hostname")][string]$csr_hostname "csr1000v",
  [Parameter(Mandatory=$false,
             HelpMessage="CSR Domain Name")][string]$csr_domainName = "lab.intra",
  [Parameter(Mandatory=$false,
             HelpMessage="CSR Admin Username")][string]$csr_username = "developer",
  [Parameter(Mandatory=$false,
             HelpMessage="CSR Admin Password")][string]$csr_password = "C1sco12345",



  [Parameter(Mandatory=$true,
             HelpMessage="CSR Mgmt IP Address as CIDR (ex. 192.168.1.10/24)")][string]$csr_mgmtIPCidr,
  [Parameter(Mandatory=$true,
             HelpMessage="CSR Mgmt network gateway.")][string]$csr_mgmtGateway,
  [Parameter(Mandatory=$false,
             HelpMessage="Source for mgmt traffic (provide 0.0.0.0/0 to allow ALL mgmt sources)")][string]$csr_mgmtNetwork = "0.0.0.0/0",


  [Parameter(Mandatory=$true,
             HelpMessage="vCenter PortGroup for GigEthernet1")][string]$csr_gig1Portgroup,
  [Parameter(Mandatory=$true,
             HelpMessage="vCenter PortGroup for GigEthernet2")][string]$csr_gig2Portgroup,
  [Parameter(Mandatory=$true,
             HelpMessage="vCenter PortGroup for GigEthernet3")][string]$csr_gig3Portgroup
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

$csrConfigHash["com.cisco.csr1000v.hostname.1"]=$csr_hostname
$csrConfigHash["com.cisco.csr1000v.domain-name.1"]=$csr_domainName
$csrConfigHash["com.cisco.csr1000v.login-username.1"]=$csr_username
$csrConfigHash["com.cisco.csr1000v.login-password.1"]=$csr_password
$csrConfigHash["com.cisco.csr1000v.privilege-password.1"]=$csr_password

$csrConfigHash["com.cisco.csr1000v.mgmt-interface.1"]="GigabitEthernet1"
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-addr.1"]=$csr_mgmtIPCidr
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-network.1"]=$csr_mgmtNetwork
$csrConfigHash["com.cisco.csr1000v.mgmt-ipv4-gateway.1"]=$csr_mgmtGateway
$csrConfigHash["com.cisco.csr1000v.mgmt-vlan.1"]=""

$csrConfigHash["com.cisco.csr1000v.enable-ssh-server.1"]="True"
$csrConfigHash["com.cisco.csr1000v.enable-scp-server.1"]="True"

$csrConfigHash["com.cisco.csr1000v.resource-template.1"]="default"
$csrConfigHash["com.cisco.csr1000v.license.1"]="ax"

$csrConfigHash["com.cisco.csr1000v.pnsc-ipv4-addr.1"]=""
$csrConfigHash["com.cisco.csr1000v.remote-mgmt-ipv4-addr.1"]=""
$csrConfigHash["com.cisco.csr1000v.pnsc-agent-local-port.1"]=""
$csrConfigHash["com.cisco.csr1000v.pnsc-shared-secret-key.1"]=""

$csrConfigHash["NetworkMapping.GigabitEthernet1"]=$csr_gig1Portgroup
$csrConfigHash["NetworkMapping.GigabitEthernet2"]=$csr_gig2Portgroup
$csrConfigHash["NetworkMapping.GigabitEthernet3"]=$csr_gig3Portgroup


Write-Host "Creating new VM from OVA $csrOvfPath named $vmName on PortGroup $csr_gig1Portgroup"
# $csr = Import-VApp $csrOvfPath -Name $vmName -OvfConfiguration $csrConfigHash -VMHost $vmhost -Location $resourcePool
$csr = Import-VApp $csrOvfPath -Name $vmName -OvfConfiguration $csrConfigHash -VMHost $vmhost

# Move-VM $csr -InventoryLocation $vmFolder
Set-VM $csr -NumCpu 4 -MemoryGB 8 -Confirm:$false

$notes = "Created On: $datestamp by $vCenterUsername
IP Address: $csr_mgmtIPCidr
Username: $csr_username
Password: $csr_password"
$temp = Set-VM $csr -Confirm:$false -Notes $notes

Write-Host "VM Created, now starting it."
$temp = Start-VM $csr

# Waiting for 6 minutes until inital boot is complete and loads configuration
Write-Host "Waiting 6 minutes to allow the CSR to install and configure."
Start-Sleep -s 360
$temp = Wait-Tools -VM $csr


Write-Host "Deployment complete."
Disconnect-VIServer -Confirm:$false
