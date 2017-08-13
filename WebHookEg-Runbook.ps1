workflow Test-StartVirtualMachinesFromWebhook
{
    param (
        [object]$WebhookData
    )

    # If runbook was called from Webhook, WebhookData will not be null.
    if ($WebhookData -ne $null) {

        # Collect properties of WebhookData
        $WebhookName     =     $WebhookData.WebhookName
        $WebhookHeaders =     $WebhookData.RequestHeader
        $WebhookBody     =     $WebhookData.RequestBody

        # Collect individual headers. VMList converted from JSON.
        $From = $WebhookHeaders.From
        $VMList = ConvertFrom-Json -InputObject $WebhookBody
        Write-Output "Runbook started from webhook $WebhookName by $From."

        # Authenticate to Azure resources
        $Cred = Get-AutomationPSCredential -Name 'MyAzureCredential'
        Add-AzureAccount -Credential $Cred

        # Start each virtual machine
        foreach ($VM in $VMList)
        {
            $VMName = $VM.Name
            Write-Output "Starting $VMName"
            Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName
        }
    }
    else {
        Write-Error "Runbook mean to be started only from webhook."
    }
}