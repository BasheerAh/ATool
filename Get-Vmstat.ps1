Write-Output "Hi World"

$usname = Get-AutomationVariable -Name 'Microsoft.Azure.Automation.SourceControl.Connection'

Write-Output $usname

$cred = Get-AutomationPSCredential -Name 'opsadmin'

