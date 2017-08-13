workflow wf-test-ps
{

  $vmname = "ARMsrv1"
  $rgName = Get-AutomationVariable -Name 'tvmrg'
#$automationconnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
#Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint $automationconnection.CertificateThumbprint -ApplicationId $automationconnection.ApplicationId -TenantId $automationconnection.TenantId 


#get-azurermvm   -name $vmname -resourcegroup $rgName
#$varname = set-automationvariable -Name 'Suspended' -Value $false
$varname = get-automationvariable -Name 'suspended' #-Value $false



Write-Output $varname
Write-Output $vmName
Write-Output "Before checkpoint"

Checkpoint-workflow

write-output "After checkpoint"

$suspended = Get-AutomationVariable -Name 'suspended'
if(!$suspended){
    set-automationvariable -Name 'suspended'

    #Force an exception
    1 + "xyz"
}

Write-output "Completed Runbook"



}