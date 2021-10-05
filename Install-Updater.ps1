[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $unstable = $false,
    [Parameter()]
    [string]
    $path = "$env:ALLUSERSPROFILE\Tailscale-updater"
)

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Not running as Admin. Nothing done."
    break
} else {
    Write-Host "Admin rights available"
}

if(-not (Test-Path -LiteralPath $path)){
    Write-Host "Creating directory $path"
    $target = New-Item -Path $path -ItemType Directory
}

Try {
    $target = Get-Item -LiteralPath $path
    Write-Host "Installing into $target"
    Get-ChildItem "Tailscale-Updater-Windows.ps1" | Copy-Item -Destination $target -Force
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -WorkingDirectory $target.FullName -Argument ('-NoProfile -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File Tailscale-Updater-Windows.ps1'+$(if($unstable){' -Track unstable'}))
    $trigger = New-ScheduledTaskTrigger -Daily -At 12:00
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Tailscale Updater" -Description "Daily Tailscale update" -User "NT AUTHORITY\SYSTEM" | Out-Null
    Write-Host "Successfully installed scheduled task"
} Catch {
    $_ | Write-Error
}
