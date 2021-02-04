# Login 
#Login-AzureRmAccount

# Variables for common values
$location = "eastus2"
$resourceGroup = "RG-ADDS"
$vmName = "SRV-DC01"
$publicIP = "pip-1"
$subnet = "subnet-1"
$vnet = "vnet-1"
$nsg = "nsg-1"
$nsgrdp = "nsgrdp"
$nic = "nic-1"

# Create resource group
New-AzureRmResourceGroup -ResourceGroupName $resourceGroup -Location $location

# Get vm credentials
$cred = Get-Credential

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $vnet `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $subnetConfig

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnet `
    -AddressPrefix 10.0.1.0/24

# Create a public IP address and specify a DNS name
$publicIP = New-AzureRmPublicIpAddress `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4 `
    -Name $publicIP

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig `
    -Name $nsgrdp `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $nsg `
    -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface `
    -Name $nic `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIP.Id `
    -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_B2s | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer -Skus 2019-Datacenter -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Create a virtual machine using the configuration
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig