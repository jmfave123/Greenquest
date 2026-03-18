# Environment Setup Guide for GreenQuest

This guide explains how to set up environment variables for the GreenQuest application following security best practices as outlined in `agent.md`.

## Why Environment Variables?

As per agent.md §3.1 - "API keys, passwords, tokens belong in environment variables":
- **Security**: Prevents secrets from being committed to version control
- **Flexibility**: Different environments (dev/staging/prod) can use different credentials
- **Team Collaboration**: Each developer can use their own credentials without conflicts

## Quick Setup

### 1. Create Your .env File

```bash
# Copy the example file
cp .env.example .env
```

### 2. Get Your Credentials

#### Cloudinary (Required for Image Uploads)
1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Sign up or log in
3. From the Dashboard, copy:
   - Cloud Name
   - API Key
   - API Secret

#### OneSignal (Required for Push Notifications)
1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Create an account or log in
3. Create a new app or select existing
4. Copy your App ID from Settings > Keys & IDs
5. Copy your REST API Key from Settings > Keys & IDs (server-side only)

### 3. Fill in Your .env File

Open `.env` and replace the placeholder values:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_actual_cloud_name
CLOUDINARY_API_KEY=your_actual_api_key
CLOUDINARY_API_SECRET=your_actual_api_secret

# OneSignal Configuration
ONESIGNAL_APP_ID=your_actual_app_id
```

### 3.1 Add Server-Only OneSignal Key in Vercel

Set this in your Vercel Project Environment Variables (do not put this in Flutter `.env`):

```env
ONESIGNAL_REST_API_KEY=your_actual_onesignal_rest_api_key
```

This key is now used only by serverless API routes (for example `api/send-notification`) so it is never embedded in the client build.

### 4. Verify Setup

```bash
# Install dependencies (if not already done)
flutter pub get

# Run the app
flutter run
```

## How It Works

### Loading Environment Variables

The app loads environment variables in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");
  
  // Rest of app initialization...
}
```

### Using Credentials Securely

**Cloudinary Config** (`lib/shared/config/cloudinary_config.dart`):
```dart
class CloudinaryConfig {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
}
```

**OneSignal** (in `main.dart`):
```dart
final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
  OneSignal.initialize(oneSignalAppId);
}
```

## Security Best Practices

✅ **DO:**
- Keep `.env` file local (never commit it)
- Use `.env.example` to share structure with team
- Add `.env` to `.gitignore` (already done)
- Rotate credentials if accidentally exposed
- Use different credentials for dev/staging/prod

❌ **DON'T:**
- Commit `.env` to version control
- Share credentials via email or chat
- Use production credentials in development
- Hardcode secrets in source code
- Store credentials in comments
- Put server-only secrets (e.g., `ONESIGNAL_REST_API_KEY`) in Flutter `.env`

## Troubleshooting

### "Warning: .env file not found"

**Solution:** Create your `.env` file:
```bash
cp .env.example .env
# Then fill in your actual credentials
```

### "CLOUDINARY_CLOUD_NAME is not configured"

**Solution:** Make sure your `.env` file contains:
```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
```
And that you've run `flutter pub get`.

### "Module not found: flutter_dotenv"

**Solution:** 
```bash
flutter pub get
flutter clean
flutter pub get
```

### App crashes on startup

**Cause:** Missing or invalid credentials

**Solution:** Verify your `.env` file has all required variables with valid values.

## Different Environments

### Development
Create `.env` with development credentials:
```env
CLOUDINARY_CLOUD_NAME=dev-greenquest
CLOUDINARY_API_KEY=dev_key
# ... etc
```

### Staging
Create `.env.staging`:
```env
CLOUDINARY_CLOUD_NAME=staging-greenquest
CLOUDINARY_API_KEY=staging_key
# ... etc
```

### Production
Create `.env.production`:
```env
CLOUDINARY_CLOUD_NAME=prod-greenquest
CLOUDINARY_API_KEY=prod_key
# ... etc
```

Load different files based on environment:
```dart
final envFile = kReleaseMode ? '.env.production' : '.env';
await dotenv.load(fileName: envFile);
```

## CI/CD Integration

For automated builds, set environment variables in your CI/CD platform:

**GitHub Actions:**
```yaml
env:
  CLOUDINARY_CLOUD_NAME: ${{ secrets.CLOUDINARY_CLOUD_NAME }}
  CLOUDINARY_API_KEY: ${{ secrets.CLOUDINARY_API_KEY }}
```

**Firebase Hosting:**
```bash
firebase functions:config:set \
  cloudinary.cloud_name="your_name" \
  cloudinary.api_key="your_key"
```

## Team Onboarding Checklist

When a new developer joins:

- [ ] Clone the repository
- [ ] Copy `.env.example` to `.env`
- [ ] Get credentials from team lead or create own dev credentials
- [ ] Fill in `.env` file
- [ ] Run `flutter pub get`
- [ ] Verify app starts without errors
- [ ] Confirm they never commit `.env` to git

## Credential Rotation

If credentials are compromised:

1. **Immediately** generate new credentials in respective platforms
2. Update `.env` file with new values
3. Notify team members to update their `.env` files
4. Audit git history to ensure no secrets were committed
5. If secrets were committed, consider them permanently compromised

## Additional Security

### For Extra Protection:

1. **Use Secret Management Services** (production):
   - AWS Secrets Manager
   - Google Cloud Secret Manager
   - HashiCorp Vault

2. **Encrypt .env file**:
   ```bash
   # Encrypt
   gpg --symmetric --cipher-algo AES256 .env
   
   # Decrypt
   gpg --decrypt .env.gpg > .env
   ```

3. **Use git-secret or blackbox** for team collaboration

## References

- [agent.md](agent.md) - Security guidelines (§3.1)
- [flutter_dotenv documentation](https://pub.dev/packages/flutter_dotenv)
- [OWASP Security Practices](https://owasp.org/www-project-mobile-security/)

## Need Help?

1. Check this file first
2. Review [CODEBASE_AUDIT_REPORT.md](CODEBASE_AUDIT_REPORT.md#1-fix-security-vulnerabilities-eta-2-hours)
3. Ask team lead for credentials (never share via insecure channels)

---

**Last Updated:** 2026-02-22  
**Maintained By:** Development Team
