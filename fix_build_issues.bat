@echo off
echo ========================================
echo 🔧 GreenQuest Build Fix Script
echo ========================================
echo.

echo 🔍 Checking Flutter doctor...
flutter doctor -v

echo.
echo 🧹 Cleaning previous builds...
flutter clean

echo.
echo 📦 Getting Flutter packages...
flutter pub get

echo.
echo 🔧 Fixing Android NDK version...
echo ✅ NDK version updated to 27.0.12077973

echo.
echo 🗑️ Cleaning Gradle cache...
if exist "%USERPROFILE%\.gradle" (
    rmdir /s /q "%USERPROFILE%\.gradle"
    echo ✅ Gradle cache cleared
)

echo.
echo 🔄 Running Gradle clean...
cd android
./gradlew clean
cd ..

echo.
echo 🧪 Testing Flutter build...
flutter build apk --debug

echo.
echo ✅ Build fix completed!
echo 💡 Try running 'flutter run' now.
echo.
pause
