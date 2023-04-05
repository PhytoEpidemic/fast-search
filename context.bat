powershell -window hidden -command ""
@echo off

echo %1 > "%AppData%\Power Search\SearchSpot.txt"

powershell Start-Process "shell:Appsfolder\33586Cherubim.PowerSearch_azr4d3dytcq80!PowerSearch" 