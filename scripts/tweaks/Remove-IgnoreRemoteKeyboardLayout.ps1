#description: Removes the setting to ignore the keyboard layout of the endpoint and keep the selected input language in the AVD session host
#execution mode: Combined
#tags: Keyboard, Language, Image

# Remove the registry value
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "IgnoreRemoteKeyboardLayout" /f | Out-Null
