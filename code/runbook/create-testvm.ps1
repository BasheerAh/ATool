#Login to PowerShell
<#$Azurecredential Get-AutomationPSCredential -Name 'AzureCredential'
Login-AzureRmAccount -Credential $Azurecredential
$SubscriptionID = Get-AutomationVariable -Name 'SubscriptionID'
#Select the Azure Subscription Free Trial or Developer Program Benefit
Set-AzureRmContext --SubscriptionId $SubscriptionID
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
       -ServicePrincipal `
       -TenantId $servicePrincipalConnection.TenantId `
       -ApplicationId $servicePrincipalConnection.ApplicationId `
       -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
   if (!$servicePrincipalConnection)
   {
      $ErrorMessage = "Connection $connectionName not found."
      throw $ErrorMessage
  } else{
      Write-Error -Message $_.Exception
      throw $_.Exception
  }
}

$SubscriptionID = Get-AutomationVariable -Name 'SubscriptionID'
Set-AzureRmContext -SubscriptionId $SubscriptionID

#intialize the variable

$rgName = Get-AutomationVariable -Name 'tvmrg'

#$rgName = "AdatumTestRG"
$PrimaryLocation = Get-AutomationVariable -Name 'PrimaryLocation'
$location = $PrimaryLocation

$vnetName = "TestVnet"
$vnetAddressprefix = "10.50.0.0/16"

$subnetName = "FrontEnd"
$subnetAddressprefix = "10.50.0.0/24"

#Create a new resource group
New-AzureRMResourceGroup -Name $rgName -Location $location

#Create a VNet
New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressprefix

#Get-Help *subnet*
#$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressprefix 
#Get-help Add-AzureRmVirtualNetworkSubnetConfig -Examples

$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

#Add Subnet to the existing VNet 
Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $subnetAddressprefix

#Save the Subnet in VNet
$vnet | Set-AzureRmVirtualNetwork


# Set variables:
$vmName = "ARMSrv1"

# Store the start time
$starttime = Get-Date

$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

#$location = $vnet.Location

# Get unique names
#Create-Names 2 #generates $storeName, $svcName
$storeName = "sta" + (Get-Date).Ticks.ToString().Substring(12)

# Create storage account:
Write-Host "Creating storage account $storeName ..." -ForegroundColor Green
$storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storeName -Type "Standard_LRS" -Location $location

Write-Host "Waiting for storage to provision ..." -ForegroundColor Green
Start-Sleep -Seconds 60

Write-Host "Identifying the VNet ..." -ForegroundColor Green
Start-Sleep -Seconds 60

$uniqueNumber = (Get-Date).Ticks.ToString().Substring(12)
$pipName = 'lab02pip' + $uniqueNumber
$nicName = 'lab02nic' + $uniqueNumber

Write-Host "Creating Public IP address ..." -ForegroundColor Green
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
Start-Sleep -Seconds 60

Write-Host "Creating NIC ..." -ForegroundColor Green
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
$credvm = Get-AutomationPSCredential -Name 'opsadmin'

#$adminUsername = $credvm.username
#$adminPassword = 'Pa$$word123'

#$securePassword = $credvm.Password
#$password       = $credvm.GetNetworkCredential().Password


#$cred = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force) 

Write-Host "Creating a VM ..." -ForegroundColor Green

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A1"
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $credvm -ProvisionVMAgent -EnableAutoUpdate
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/WindowsVMosDisk.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm 

# Display time taken for script to complete
$endtime = Get-Date
Write-Host Started at $starttime -ForegroundColor Magenta
Write-Host Ended at $endtime -ForegroundColor Yellow
Write-Host " "
$elapsed = $endtime - $starttime

If ($elapsed.Hours -ne 0){
  Write-Host Total elapsed time is $elapsed.Hours hours $elapsed.Minutes minutes -ForegroundColor Green
}
Else {
  Write-Host Total elapsed time is $elapsed.Minutes minutes -ForegroundColor Green
}
Write-Host " "





