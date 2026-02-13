@echo off
echo Killing all Chrome instances...
taskkill /F /IM chrome.exe /T 2>nul
timeout /t 2 /nobreak >nul

echo Starting Flutter Web with stable settings...
flutter run -d chrome --web-browser-flag="--disable-extensions" --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=%TEMP%\chrome_dev_profile"
