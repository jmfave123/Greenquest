# 🔧 Fix Terminal Copy/Paste Settings

Your terminal is showing `^C` instead of copying because `Ctrl + C` is set to **interrupt** instead of **copy**.

## 🛠️ **Quick Fixes:**

### **Method 1: Enable Quick Edit Mode (Command Prompt)**

1. **Right-click** on the title bar of your terminal window
2. Select **"Properties"**
3. Go to the **"Options"** tab
4. Check the box **"Quick Edit Mode"**
5. Click **"OK"**

Now you can:
- **Left-click and drag** to select text
- **Right-click** to copy/paste
- **Ctrl + C** will still interrupt, but you can use right-click to copy

### **Method 2: Use Right-Click for Copy/Paste**

Even without Quick Edit Mode:
1. **Select text** by clicking and dragging
2. **Right-click** on selected text → Choose **"Copy"**
3. **Right-click** in terminal → Choose **"Paste"**

### **Method 3: Alternative Keyboard Shortcuts**

| Action | Command Prompt | PowerShell | Windows Terminal |
|--------|----------------|------------|------------------|
| **Copy** | Right-click | `Ctrl + Shift + C` | `Ctrl + Shift + C` |
| **Paste** | Right-click | `Ctrl + Shift + V` | `Ctrl + Shift + V` |
| **Select All** | `Ctrl + A` | `Ctrl + A` | `Ctrl + A` |

### **Method 4: Switch to Windows Terminal (Recommended)**

Windows Terminal has better copy/paste support:

1. **Download Windows Terminal** from Microsoft Store
2. **Or** use PowerShell ISE
3. **Or** use VS Code integrated terminal

## 🔄 **For Your Current Session:**

Since you're using PowerShell, try these shortcuts:

### **Copy Text:**
1. **Select text** with mouse
2. Press **`Ctrl + Shift + C`** (not just `Ctrl + C`)

### **Paste Text:**
1. Press **`Ctrl + Shift + V`** (not just `Ctrl + V`)

### **Alternative Method:**
1. **Select text** with mouse
2. **Right-click** → **"Copy"**
3. **Right-click** → **"Paste"**

## 🎯 **Why This Happens:**

- **`Ctrl + C`** = **Interrupt signal** (stops running programs)
- **`Ctrl + Shift + C`** = **Copy text** (in PowerShell/Windows Terminal)
- **Right-click** = **Copy/Paste menu** (works in most terminals)

## 🚀 **Test the Fix:**

Try copying this text using the new method:
1. Select the text below
2. Use `Ctrl + Shift + C` or right-click → Copy
3. Try pasting it somewhere

```
Test copy functionality - if you can copy this, it's working!
```

## 💡 **Pro Tips:**

1. **Enable Quick Edit Mode** for easiest copying
2. **Use Windows Terminal** for best experience
3. **Remember**: `Ctrl + C` stops programs, `Ctrl + Shift + C` copies text
4. **Right-click** always works for copy/paste in Windows terminals

---

**Try `Ctrl + Shift + C` instead of `Ctrl + C` for copying!**
