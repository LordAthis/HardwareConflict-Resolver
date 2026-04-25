$AuditFile = ".\LOG\Hardware_Audit.log"
"--- HARDWARE AUDIT $(Get-Date) ---" > $AuditFile
Get-PnpDevice | Where-Object { $_.Status -ne "OK" } | Select-Object FriendlyName, InstanceId, Status, Problem | Out-File -FilePath $AuditFile -Append
