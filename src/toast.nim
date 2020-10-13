import os, strformat, oids, osproc

type Duration = enum
  dShort = "short",
  dLong = "long"

type Notification* = ref object
  appId: string
  icon: string
  expiration: int

proc invokeTempScript(content: string) =
  let
    id = genOid()
    filename = joinPath([getTempDir(), $id & ".ps1"])
  try:
    writeFile(filename, "\uFEFF" & content)
    discard execCmd("PowerShell -ExecutionPolicy Bypass -File " & filename)
  finally:
    removeFile(filename)

proc newNotification(appId: string = "NimApp", icon: string = ""): Notification =
  var n: Notification
  new n
  n.appId = appId
  n.icon = icon
  return n

proc show(n: Notification, title = "", text = "", icon = "", duration = dShort, expiration = 600) =
  var icon = if (icon == ""): n.icon else: icon
  let toastTemplate = &"""[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$APP_ID = '{n.appId}'
$template = @"
<toast activationType="protocol" duration="{duration}">
    <visual>
        <binding template="ToastGeneric">
            <image placement="appLogoOverride" src="{icon}" />
            <text><![CDATA[{title}]]></text>
            <text><![CDATA[{text}]]></text>
        </binding>
    </visual>
</toast>
"@
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
$toast.ExpirationTime = (Get-Date).AddSeconds({expiration})
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID).Show($toast)"""
  invokeTempScript(toastTemplate)



when isMainModule:
  let
    iconPath = "C:\\Users\\roose\\projects\\sandbox\\nim-toast\\images\\nim.png"
    n = newNotification("NimToast", iconPath)
  n.show("Task complete", "Documentation has been successfully generated")
