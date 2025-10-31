# 🚀 GreenQuest Deployment Guide for Vercel

This guide will help you deploy the GreenQuest Flutter web application to Vercel.

## Prerequisites

1. ✅ **Vercel Account** - Sign up at [vercel.com](https://vercel.com)
2. ✅ **GitHub Repository** - Your code is already on GitHub
3. ✅ **Flutter SDK** - For local testing (optional)

## 📋 Steps to Deploy

### Step 1: Import Your Project to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Click **"Add New..."** → **"Project"**
3. Import your GitHub repository: `jmfave123/Greenquest`
4. Vercel will automatically detect the `vercel.json` configuration

### Step 2: Configure Build Settings

In the Vercel project settings, configure:

**Framework Preset:** `Other`
**Root Directory:** `./`
**Build Command:** `bash build.sh`
**Output Directory:** `build/web`
**Install Command:** `flutter pub get`

### Step 3: Environment Variables

Add these environment variables in Vercel's project settings:

```bash
# Firebase Configuration (Web)
FIREBASE_API_KEY=AIzaSyBKn6_xud23ZY_Jm4A_TTLYgcE2YW5AjVY
FIREBASE_APP_ID=1:523977270593:web:9f87dfe5a259bb71bc2dc0
FIREBASE_MESSAGING_SENDER_ID=523977270593
FIREBASE_PROJECT_ID=greenquest-2b976
FIREBASE_AUTH_DOMAIN=greenquest-2b976.firebaseapp.com
FIREBASE_STORAGE_BUCKET=greenquest-2b976.firebasestorage.app
FIREBASE_MEASUREMENT_ID=G-DLVEEJ3LFT

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=dddnu6i5q
CLOUDINARY_API_KEY=333337596671818
CLOUDINARY_API_SECRET=UJKccyN0O_VjmG9QrEvsU_f9lxA
CLOUDINARY_DEFAULT_FOLDER=greenquest
```

### Step 4: Deploy

1. Click **"Deploy"**
2. Wait for the build to complete (usually 3-5 minutes)
3. Your app will be live at a URL like: `https://greenquest.vercel.app`

## 🔧 Important Notes

### Current Configuration
Your `firebase_options.dart` and `cloudinary_config.dart` are **hardcoded** in the source code. This means:
- ✅ **No action needed** - Your credentials are already in the code
- ⚠️ **Security consideration** - These are client-side keys and are safe to expose in the frontend

### Build Requirements
- **Flutter SDK**: Vercel will use Flutter during build
- **Build time**: Expect 3-5 minutes for first build
- **Build cache**: Subsequent builds are faster

## 📁 Project Structure for Vercel

```
greenquest/
├── build.sh          # Build script
├── vercel.json       # Vercel configuration
├── web/              # Web assets
├── build/web/        # Generated output (created during build)
└── lib/              # Your Flutter code
```

## 🔍 Troubleshooting

### Build Fails
- Check Vercel logs for error messages
- Ensure Flutter is properly detected
- Verify all dependencies are in `pubspec.yaml`

### App Not Loading
- Check browser console for errors
- Verify Firebase credentials are correct
- Ensure `base-href` is set to `/`

### Missing Files
- Ensure `.gitignore` doesn't exclude necessary files
- Check that `build/web` directory is generated

## 🌐 Custom Domain (Optional)

1. Go to Project Settings → Domains
2. Add your custom domain
3. Configure DNS as instructed by Vercel

## 📱 PWA Features

Your app is configured as a Progressive Web App:
- ✅ Service Worker
- ✅ Web Manifest
- ✅ App Icons
- ✅ Offline Support

## 🔐 Security

Current setup includes:
- ✅ Firebase Authentication
- ✅ CORS configuration
- ✅ Secure headers in `vercel.json`
- ⚠️ Cloudinary secret is in client-side code (safe for client-side usage)

## 📚 Additional Resources

- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Deployment](https://flutter.dev/docs/deployment/web)
- [Firebase Web Setup](https://firebase.google.com/docs/web/setup)

## ✅ Quick Checklist

- [ ] Import project to Vercel
- [ ] Set build command to `bash build.sh`
- [ ] Set output directory to `build/web`
- [ ] Configure environment variables (optional - already in code)
- [ ] Deploy
- [ ] Test the live URL
- [ ] Set up custom domain (optional)

---

**Need Help?** Check the Vercel logs or contact support.

