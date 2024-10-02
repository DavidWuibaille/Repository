# Check if shell launcher license is enabled
function Check-ShellLauncherLicenseEnabled
{
    [string]$source = @"
using System;
using System.Runtime.InteropServices;

static class CheckShellLauncherLicense
{
    const int S_OK = 0;

    public static bool IsShellLauncherLicenseEnabled()
    {
        int enabled = 0;

        if (NativeMethods.SLGetWindowsInformationDWORD("EmbeddedFeature-ShellLauncher-Enabled", out enabled) != S_OK) {
            enabled = 0;
        }
        return (enabled != 0);
    }

    static class NativeMethods
    {
        [DllImport("Slc.dll")]
        internal static extern int SLGetWindowsInformationDWORD([MarshalAs(UnmanagedType.LPWStr)]string valueName, out int value);
    }

}
"@

    $type = Add-Type -TypeDefinition $source -PassThru

    return $type[0]::IsShellLauncherLicenseEnabled()
}

[bool]$result = $false

$result = Check-ShellLauncherLicenseEnabled
"`nShell Launcher license enabled is set to " + $result
if (-not($result))
{
    "`nThis device doesn&#39;t have required license to use Shell Launcher"
    exit
}

$COMPUTER = "localhost"
$NAMESPACE = "root\standardcimv2\embedded"

# Create a handle to the class instance so we can call the static methods.
try {
    $ShellLauncherClass = [wmiclass]"\\$COMPUTER\${NAMESPACE}:WESL_UserSetting"
    } catch [Exception] {
    write-host $_.Exception.Message; 
    write-host "Make sure Shell Launcher feature is enabled"
    exit
    }


# This well-known security identifier (SID) corresponds to the BUILTIN\Administrators group.

$Admins_SID = "S-1-5-32-544"

# Create a function to retrieve the SID for a user account on a machine.

function Get-UsernameSID($AccountName) {

    $NTUserObject = New-Object System.Security.Principal.NTAccount($AccountName)
    $NTUserSID = $NTUserObject.Translate([System.Security.Principal.SecurityIdentifier])

    return $NTUserSID.Value
}

# Get the SID for a user account named "Cashier". Rename "Cashier" to an existing account on your system to test this script.
$Cashier_SID_supervision = Get-UsernameSID("w_supervision")

# Define actions to take when the shell program exits.
$restart_shell = 0
$restart_device = 1
$shutdown_device = 2

# This example sets the command prompt as the default shell, and restarts the device if the command prompt is closed. 
$ShellLauncherClass.SetDefaultShell("explorer.exe", $restart_device)

# Display the default shell to verify that it was added correctly.
$DefaultShellObject = $ShellLauncherClass.GetDefaultShell()
"`nDefault Shell is set to " + $DefaultShellObject.Shell + " and the default action is set to " + $DefaultShellObject.defaultaction

# Set Internet Explorer as the shell for "Cashier", and restart the machine if Internet Explorer is closed.
$ShellLauncherClass.SetCustomShell($Cashier_SID_supervision, "c:\exploit\supervision.cmd", ($null), ($null), $restart_shell)

# View all the custom shells defined.
"`nCurrent settings for custom shells:"
Get-WmiObject -namespace $NAMESPACE -computer $COMPUTER -class WESL_UserSetting | Select Sid, Shell, DefaultAction

# Enable Shell Launcher
$ShellLauncherClass.SetEnabled($TRUE)
$IsShellLauncherEnabled = $ShellLauncherClass.IsEnabled()
"`nEnabled is set to " + $IsShellLauncherEnabled.Enabled

# Remove the new custom shells.
# $ShellLauncherClass.RemoveCustomShell($Admins_SID)
# $ShellLauncherClass.RemoveCustomShell($Cashier_SID)

# Disable Shell Launcher
# $ShellLauncherClass.SetEnabled($FALSE)
# $IsShellLauncherEnabled = $ShellLauncherClass.IsEnabled()
# "`nEnabled is set to " + $IsShellLauncherEnabled.Enabled
