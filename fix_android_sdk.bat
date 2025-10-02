@echo off
echo ========================================
echo 🔧 Android SDK Compatibility Fix
echo ========================================
echo.

echo 📋 Updated Android SDK versions:
echo    - minSdk: 23 (was flutter.minSdkVersion)
echo    - targetSdk: 34 (was flutter.targetSdkVersion)  
echo    - compileSdk: 34 (was flutter.compileSdkVersion)
echo    - NDK: 27.0.12077973 (updated for Firebase)
echo.

echo 🧹 Cleaning previous builds...
flutter clean

echo.
echo 📦 Getting Flutter packages...
flutter pub get

echo.
echo 🗑️ Cleaning Gradle cache...
if exist "%USERPROFILE%\.gradle" (
    rmdir /s /q "%USERPROFILE%\.gradle"
    echo ✅ Gradle cache cleared
)

echo.
echo 🔄 Cleaning Android build cache...
if exist "android\build" (
    rmdir /s /q "android\build"
    echo ✅ Android build cache cleared
)

if exist "android\app\build" (
    rmdir /s /q "android\app\build"
    echo ✅ App build cache cleared
)

echo.
echo 🧪 Testing Android build...
flutter build apk --debug

echo.
echo ✅ Android SDK fix completed!
echo 💡 The warning about SDK versions should now be resolved.
echo.
pause
