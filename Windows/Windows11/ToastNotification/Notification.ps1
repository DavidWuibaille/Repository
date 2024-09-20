powershellCopier le code# Get the current path of the script
$CurrentPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

# Define notification parameters
$notificationTitle = "Migration Windows 10"
$Scenario          = "short" # Possible values: reminder | short | long
$Logo              = $CurrentPath + "\Logo.jpg"
$AttributionText   = "Upgrade"
$TitreToast        = "LANDESK"
$TitleMessage      = "Windows 10 upgrade"
$Message1          = "The Windows 10 migration has started"
$Message2          = "Please do not restart your computer"
$TextBouton        = "Close"

# Define the XML for the toast notification
$Toast = @"
<toast scenario="$Scenario">
    <visual>
        <binding template="ToastGeneric">
            <image id="1" placement="appLogoOverride" hint-crop="circle" src="$Logo"/>
            <text placement="attribution">$AttributionText</text>
            <text>$TitreToast</text>
            <group>
                <subgroup>
                    <text hint-style="title" hint-wrap="true">$TitleMessage</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">$Message1</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">$Message2</text>
                </subgroup>
            </group>
        </binding>
    </visual>
    <actions>
        <action activationType="system" arguments="dismiss" content="$TextBouton"/>
    </actions>
</toast>
"@

# Load the necessary Windows Runtime assemblies
$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

# Define the application ID (PowerShell)
$App = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

# Load the notification into the required format
$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($Toast.OuterXml)

# Display the toast notification
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)