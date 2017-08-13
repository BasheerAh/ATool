$uri = "https://s1events.azure-automation.net/webhooks?token=BUsHuJeh8mJ8gBArl2%2bByqUdU7xqBUeOldXmr%2f6w7u8%3d"
$headers = @{"From"="iass.lab@outlook.com";"Date"="08/13/2017 15:38:00"}

$vms  = @(
            @{ Name="vm01";ServiceName="vm01"},
            @{ Name="vm02";ServiceName="vm02"}
        )
$body = ConvertTo-Json -InputObject $vms

$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
$jobid = ConvertFrom-Json $response