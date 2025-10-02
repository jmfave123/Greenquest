# 🚨 GreenQuest Build Fix Guide

Your Flutter build is failing due to **disk space issues** and **NDK version mismatch**. Here's how to fix it:

## 🔥 **CRITICAL ISSUES IDENTIFIED:**

### 1. **Disk Space Full** 💾
- **Error**: "There is not enough space on the disk"
- **Impact**: Cannot download dependencies or build the app

### 2. **Android NDK Version Mismatch** ⚙️
- **Current NDK**: 26.3.11579264
- **Required NDK**: 27.0.12077973
- **Status**: ✅ **FIXED** - Updated in `android/app/build.gradle.kts`

## 🛠️ **IMMEDIATE FIXES NEEDED:**

### **Step 1: Free Up Disk Space** 🧹

#### **Option A: Run the Cleanup Script (Recommended)**
```bash
# Double-click the cleanup_disk_space.bat file I created
# OR run it from command prompt:
cleanup_disk_space.bat
```

#### **Option B: Manual Cleanup Commands**
```bash
# 1. Clean Flutter cache
flutter clean

# 2. Remove Gradle cache (LARGE space saver)
rmdir /s /q "%USERPROFILE%\.gradle"

# 3. Remove Android cache
rmdir /s /q "%USERPROFILE%\.android"

# 4. Remove Dart cache
rmdir /s /q "%USERPROFILE%\.dartServer"

# 5. Remove project build cache
rmdir /s /q "build"
rmdir /s /q ".dart_tool"

# 6. Clean Windows temp files
del /q /f /s "%TEMP%\*"
```

#### **Option C: Disk Cleanup Tool**
1. Press `Win + R`
2. Type `cleanmgr` and press Enter
3. Select C: drive
4. Check all boxes and click OK

### **Step 2: Verify NDK Fix** ✅
The NDK version has been updated in `android/app/build.gradle.kts`:
```kotlin
android {
    ndkVersion = "27.0.12077973"  // ✅ Updated from flutter.ndkVersion
}
```

### **Step 3: Rebuild Project** 🔄
```bash
# 1. Clean everything
flutter clean

# 2. Get packages
flutter pub get

# 3. Try building again
flutter run
```

## 🚀 **QUICK FIX SCRIPT:**

I've created `fix_build_issues.bat` - run it to automatically fix everything:

```bash
fix_build_issues.bat
```

## 📊 **Disk Space Requirements:**

Flutter projects typically need:
- **Minimum**: 2-3 GB free space
- **Recommended**: 5-10 GB free space
- **For Android builds**: Additional 2-3 GB

## 🔍 **Check Available Space:**

### **Windows Command:**
```bash
wmic logicaldisk get size,freespace,caption
```

### **PowerShell:**
```powershell
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
```

## 🎯 **Expected Results After Fix:**

1. **Disk Space**: At least 3-5 GB free
2. **NDK Version**: 27.0.12077973
3. **Build Status**: ✅ Successful
4. **App Launch**: ✅ Working

## 🆘 **If Still Having Issues:**

### **Alternative Solutions:**

1. **Use Different Drive:**
   ```bash
   # Move project to D: drive if you have more space
   xcopy "C:\Users\Lenovo Thinkpad\Desktop\greenquest" "D:\greenquest" /E /I
   cd D:\greenquest
   flutter run
   ```

2. **Clean Specific Folders:**
   ```bash
   # Clean only Gradle cache (biggest space saver)
   rmdir /s /q "%USERPROFILE%\.gradle"
   ```

3. **Use Flutter Web Instead:**
   ```bash
   flutter run -d chrome
   ```

## 📱 **Test Commands:**

After cleanup, test with:
```bash
# Check Flutter status
flutter doctor -v

# Clean build
flutter clean && flutter pub get

# Try building
flutter build apk --debug

# Run the app
flutter run
```

## ⚠️ **Important Notes:**

1. **Backup Important Files** before running cleanup scripts
2. **Gradle cache** can be 1-5 GB - removing it will free significant space
3. **First build** after cleanup will take longer (downloading dependencies)
4. **NDK version** is now fixed and should resolve Firebase plugin issues

## 🎉 **Success Indicators:**

- ✅ No "disk space" errors
- ✅ No NDK version warnings
- ✅ Successful `flutter run`
- ✅ App launches on device/emulator

---

**Run the cleanup script first, then try `flutter run` again!**
