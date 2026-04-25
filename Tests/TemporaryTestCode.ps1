Get-PnpDevice -FriendlyName "*Keyboard*", "*HID-compliant*", "*Mouse*" | Enable-PnpDevice -Confirm:$false
