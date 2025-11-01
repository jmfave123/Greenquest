# ⚡ Quick Deploy to Vercel

## One-Click Deploy

1. Go to: https://vercel.com/new
2. Click **"Import Git Repository"**
3. Select: **jmfave123/Greenquest**
4. Click **"Deploy"** → Done! 🎉

## Manual Setup (if needed)

### Configure Build Settings in Vercel:

**Framework Preset:** Other  
**Build Command:** `bash build.sh`  
**Output Directory:** `build/web`  
**Install Command:** `flutter pub get`

### That's it! 

Your app will be live at: `https://greenquest.vercel.app`

---

## 📝 Environment Variables (Optional)

Your Firebase and Cloudinary credentials are **already hardcoded** in the source code, so you don't need to add them.

But if you want to use environment variables instead, add these in Vercel's settings:

```
FIREBASE_API_KEY=AIzaSyBKn6_xud23ZY_Jm4A_TTLYgcE2YW5AjVY
FIREBASE_PROJECT_ID=greenquest-2b976
FIREBASE_AUTH_DOMAIN=greenquest-2b976.firebaseapp.com
FIREBASE_STORAGE_BUCKET=greenquest-2b976.firebasestorage.app
CLOUDINARY_CLOUD_NAME=dddnu6i5q
CLOUDINARY_API_KEY=333337596671818
```

---

## 🔧 Troubleshooting

**Build fails?** Check Vercel logs  
**App not loading?** Check browser console  
**Need help?** See `DEPLOYMENT_GUIDE.md`

