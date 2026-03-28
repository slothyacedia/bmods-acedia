@echo off
setlocal EnableDelayedExpansion

REM === CONFIG ===
set "appID=2592170"
set "gameFolderName=Bot Maker For Discord"
set "exeName=Bot Maker For Discord.exe"
set "zipName=bmods.zip"
set "extractedDir=bmods-master"
set "wget=0"
set "winget=0"

echo Starting bmods Installer v1.1...
echo Detecting Steam Installation...

REM === Get Steam install path from registry ===
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul') do (
    set "steamRoot=%%B"
)

if not defined steamRoot (
    echo ERROR: Steam Installation Not Found.
    pause
    exit /b 1
)

echo Found Steam At "%steamRoot%"
set "steamApps=%steamRoot%\steamapps"

REM === Initialize installDir ===
set "installDir="

REM === Check default Steam library ===
echo Scanning Default Steam Library...
if exist "%steamApps%\common\%gameFolderName%\%exeName%" (
    set "installDir=%steamApps%\common\%gameFolderName%"
    echo Found BMD In Default Library: "%installDir%"
    goto :found
) else (
    echo Not Found In Default Library.
)

REM === Check additional Steam libraries ===
for /f "tokens=2 delims=	" %%A in ('findstr /i "path" "%steamApps%\libraryfolders.vdf" 2^>nul') do (
    set "libraryPath=%%A"
    set "libraryPath=!libraryPath:"=!"   REM remove quotes
    if exist "!libraryPath!\steamapps\common\%gameFolderName%\%exeName%" (
        set "installDir=!libraryPath!\steamapps\common\%gameFolderName%"
        echo Found BMD In Additional Library: "!installDir!"
        goto :found
    ) else (
        echo Not Found In "!libraryPath!\steamapps\common"
    )
)

echo ERROR: Bot Maker For Discord.exe Not Found In Any Steam Library.
pause
exit /b 1

:found
echo Installing bmods To: "%installDir%"
timeout /t 1 >nul

REM === Download and extract bmods ===
echo Downloading bmods zip...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/RatWasHere/bmods/archive/refs/heads/master.zip' -OutFile '%zipName%'"
if errorlevel 1 (
    echo ERROR: Failed To Download bmods.
    pause
    exit /b 1
)

echo Extracting bmods...
powershell -Command "Expand-Archive -Path '%zipName%' -DestinationPath . -Force"
if errorlevel 1 (
    echo ERROR: Failed To Extract bmods.
    pause
    exit /b 1
)
del "%zipName%"

REM === Destination folders ===
set "actionsDest=%installDir%\AppData\Actions"
set "eventsDest=%installDir%\AppData\Events"
set "themesDest=%installDir%\Themes"
set "automationsDest=%installDir%\Automations"

echo Copying Actions...
xcopy "%extractedDir%\Actions" "%actionsDest%" /E /Y
echo Copying Themes...
xcopy "%extractedDir%\Themes" "%themesDest%" /E /Y
echo Copying Events...
xcopy "%extractedDir%\Events" "%eventsDest%" /E /Y
echo Copying Automations...
xcopy "%extractedDir%\Automations" "%automationsDest%" /E /Y

echo Cleaning Up...
rd /S /Q "%extractedDir%"

echo bmods Installation Complete!
pause
exit /b 0
