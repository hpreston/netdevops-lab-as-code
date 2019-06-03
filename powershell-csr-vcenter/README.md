# Deploying CSR1000v to vCenter from OVA with PowerShell

[![published](https://static.production.devnetcloud.com/codeexchange/assets/images/devnet-published.svg)](https://developer.cisco.com/codeexchange/github/repo/hpreston/netdevops-lab-as-code)

In this example we'll deploy a Cisco CSR1000v to vCenter completely with code, no GUI needed.  

## Requirements 

* You'll need to [download the OVA for the CSR from cisco.com](https://software.cisco.com/download/home/284364978/type/282046477) for the version you'd like to deploy.  
* You'll need to [install PowerShell on your workstation](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-6).  *PowerShell Core for macOS or Linux will work fine.*  
* You'll need to [install PowerCLI](https://www.powershellgallery.com/packages/VMware.PowerCLI/10.1.1.8827524) from VMware to interact with vCenter. 
* You'll need to [install Python 3.6+](https://www.python.org/downloads/) on your workstation.  

## Running the Scripts
Now that you've setup the pre-reqs you can jump in and run the script.  

1. Clone this repo and change into the right directory. 

	```bash
	git clone https://github.com/hpreston/netdevops-lab-as-code
	cd powershell-csr-vcenter
	```

1. Setup a Python venv (for deploying a baseline configuration with NetMiko). 

	```bash
	python3.6 -m venv venv 
	source venv/bin/activate 
	pip install -r requirements.txt 
	```

1. Run the [`deploy_csr.ps1`](deploy_csr.ps1) PowerShell Script.  The script leverages several parameters for key details of the deployment.  The minimum needed parameters are shown here, and if any of these are left out you'll be asked to provide them.  

	```bash
	# Example
	pwsh deploy_csr.ps1 \
	  --vCenterServerHost vcenter.lab.intra \
	  --vCenterUsername vcenterUser \
	  --vCenterPassword SecurePass \
	  --computeCluster "Lab-Cluster" \
	  --vmName labcsr1 \
	  --csrOvfPath "~/Downloads/csr1000v-universalk9.16.11.01a.ova" \
	  --csr_mgmtIPCidr 192.168.1.11/24 \
	  --csr_mgmtGateway 192.168.1.1 \
	  --csr_gig1Portgroup labnet1 \
	  --csr_gig2Portgroup labnet2 \
	  --csr_gig3Portgroup labnet3
	```
	
	* The full list of mandartory paramters are: 
		* `vCenterServerHost` - HelpMessage="vCenter IP or FQDN"
		* `vCenterUsername` - HelpMessage="vCenter User Account"
		* `vCenterPassword` - HelpMessage="vCenter User Password"
		* `computeCluster` - HelpMessage="vCenter Compute Cluster to deploy CSR onto."
		* `vmName` - HelpMessage="Name of the VM in vCenter"
		* `csrOvfPath` - HelpMessage="Location of CSR OVA file to deploy."
		* `csr_mgmtIPCidr` - HelpMessage="CSR Mgmt IP Address as CIDR (ex. 192.168.1.10/24)"
		* `csr_mgmtGateway` - HelpMessage="CSR Mgmt network gateway."
		* `csr_gig1Portgroup` - HelpMessage="vCenter PortGroup for GigEthernet1"
		* `csr_gig2Portgroup` - HelpMessage="vCenter PortGroup for GigEthernet2"
		* `csr_gig3Portgroup` - HelpMessage="vCenter PortGroup for GigEthernet3"
	* The full list of optional paramters and their defaults are: 
		* `csr_hostname` - HelpMessage="CSR Hostname" 
			* Default Value = "`csr1000v`"
		* `csr_domainName` - HelpMessage="CSR Domain Name"
			* `Default` Value = "`lab.intra`"
		* `csr_username` - HelpMessage="CSR Admin Username"
			* Default Value = "`developer`"
		* `csr_password` - HelpMessage="CSR Admin Password"
			* Default Value = "`C1sco12345`"
		* `csr_mgmtNetwork` - HelpMessage="Source for mgmt traffic (provide 0.0.0.0/0 to allow ALL mgmt sources)"
			* Default Value = "`0.0.0.0/0`"
	
	* The script will look like this as it runs: 

		```bash
		Creating new VM from OVA ~/Downloads/csr1000v-universalk9.16.11.01a.ova named labcsr1 on PortGroup lab-net1
		
		PowerState              : PoweredOff                                                                                                                       Version                 : v13                                                                                                                              HardwareVersion         : vmx-13
		.
		<MORE VCENTER DETAILS>
		.
		
		VM Created, now starting it. 
		Waiting 6 minutes to allow the CSR to install and configure.                                                                                               
		Deployment complete.                                                                                                                                       
		New CSR VM named labcsr1 with hostname csr1000v has IP 192.168.1.11/24 and 
		credentials of developer / C1sco12345
		```

1. At this point the VM should be up and reachable at the MgmtIP you gave with the credentials (either default or custom if you provided new ones).  
1. If you'd like to lay down a generic configuration baseline to the router, a [`baseline_configure.py`](baseline_configure.py) script is included that enables NETCONF/RESTCONF.  But you can open up the script and add additional configuraiton to it as well.  To run the baseline, check it out like this: 

	```bash
	# Checkout the parameters
	$ python baseline_configure.py --help
	usage: baseline_configure.py [-h] --address ADDRESS [--username USERNAME]
	                             [--password PASSWORD] [--ssh_port SSH_PORT]
	                             [--device_type DEVICE_TYPE]
	
	optional arguments:
	  -h, --help            show this help message and exit
	  --address ADDRESS     Device Address
	  --username USERNAME   Device User - default = 'developer'
	  --password PASSWORD   Device Password - default = 'C1sco12345'
	  --ssh_port SSH_PORT   Device SSH Port - default = 22
	  --device_type DEVICE_TYPE
	                        NetMiko Device Type - defaulte = 'cisco_ios'
	
	# Run with defaults (and IP of new router) 
	python baseline_configure.py --address 192.168.1.11
	
	# Output 
	Sending baseline configuraiton to device at address 192.168.1.11
	The following configuration was sent:
	config term
	Enter configuration commands, one per line.  End with CNTL/Z.
	csr1000v(config)#netconf-yang
	csr1000v(config)#restconf
	csr1000v(config)#end
	csr1000v#
	Building configuration...
	[OK]
	```
	
1. All done!  