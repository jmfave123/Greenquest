@echo off
echo ========================================
echo 🧹 GreenQuest Disk Space Cleanup Script
echo ========================================
echo.

echo 🔍 Checking disk space...
wmic logicaldisk where size^>0 get size,freespace,caption

echo.
echo 🗑️ Cleaning Flutter cache...
if exist "%USERPROFILE%\.gradle" (
    echo Removing Gradle cache...
    rmdir /s /q "%USERPROFILE%\.gradle"
    echo ✅ Gradle cache cleared
) else (
    echo ⚠️ Gradle cache not found
)

if exist "%USERPROFILE%\.android" (
    echo Removing Android cache...
    rmdir /s /q "%USERPROFILE%\.android"
    echo ✅ Android cache cleared
) else (
    echo ⚠️ Android cache not found
)

if exist "%USERPROFILE%\.dartServer" (
    echo Removing Dart cache...
    rmdir /s /q "%USERPROFILE%\.dartServer"
    echo ✅ Dart cache cleared
) else (
    echo ⚠️ Dart cache not found
)

echo.
echo 🧹 Cleaning Flutter build cache...
cd /d "C:\Users\%USERNAME%\Desktop\greenquest"
if exist "build" (
    rmdir /s /q "build"
    echo ✅ Flutter build cache cleared
)

if exist ".dart_tool" (
    rmdir /s /q ".dart_tool"
    echo ✅ Dart tool cache cleared
)

echo.
echo 🗑️ Cleaning Windows temp files...
del /q /f /s "%TEMP%\*" 2>nul
echo ✅ Windows temp files cleared

echo.
echo 🧹 Running Flutter clean...
flutter clean
echo ✅ Flutter clean completed

echo.
echo 🔍 Final disk space check...
wmic logicaldisk where size^>0 get size,freespace,caption

echo.
echo ✅ Cleanup completed!
echo 💡 You should now have more disk space available.
echo.
pause
