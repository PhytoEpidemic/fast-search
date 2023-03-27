::powershell -window hidden -command ""
powershell -ExecutionPolicy Bypass -File mkshortcut.ps1

if exist shortcut.lnk (
    shortcut.lnk
) else (
    powershell -ExecutionPolicy Bypass -File search.ps1
)
