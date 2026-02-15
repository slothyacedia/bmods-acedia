@echo off

xcopy /y "Fixes" "./Actions"
xcopy /y "Tweaks" "./Actions"
echo Merging Done.
timeout /t 5

rmdir /s /q "Fixes"
rmdir /s /q "Tweaks"
echo Cleanup Done.
timeout /t 5