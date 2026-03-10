const admin = require('firebase-admin');
const crypto = require('crypto');

function parsePrivateKey(raw) {
  if (!raw) return '';
  return raw
    .replace(/^["']|["']$/g, '')  // strip surrounding quotes
    .replace(/\\n/g, '\n')         // literal \n → real newline
    .replace(/\r\n/g, '\n')        // CRLF → LF
    .trim();
}

function getDb() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: parsePrivateKey(process.env.FIREBASE_PRIVATE_KEY),
      }),
    });
  }
  return admin.firestore();
}

const OTP_COLLECTION = 'otp_verifications';
const MAX_ATTEMPTS = 5;

function hashOtp(salt, code) {
  return crypto.createHash('sha256').update(salt + code).digest('hex');
}

module.exports = async (req, res) => {
  // CORS headers — required for Flutter web
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed.' });
  }

  try {
    // --- Authenticate the request ---
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'Unauthorized.' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    const db = getDb();
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // --- Validate submitted code format ---
    const { code } = req.body;
    if (!code || !/^\d{6}$/.test(code)) {
      return res.status(400).json({ success: false, error: 'Please enter a valid 6-digit OTP.' });
    }

    // --- Fetch stored OTP record ---
    const otpRef = db.collection(OTP_COLLECTION).doc(uid);
    const otpDoc = await otpRef.get();

    if (!otpDoc.exists) {
      return res.status(400).json({ success: false, error: 'No OTP found. Please request a new one.' });
    }

    const otpData = otpDoc.data();

    // --- Check expiry ---
    if (otpData.expiresAt.toDate() < new Date()) {
      await otpRef.delete();
      return res.status(400).json({ success: false, error: 'OTP has expired. Please request a new one.' });
    }

    // --- Check max attempts (brute-force protection) ---
    if (otpData.attempts >= MAX_ATTEMPTS) {
      await otpRef.delete();
      return res.status(400).json({
        success: false,
        error: 'Too many failed attempts. Please request a new OTP.',
      });
    }

    // --- Verify code (constant-time comparison via hashing) ---
    const hashedSubmitted = hashOtp(otpData.salt, code);
    if (hashedSubmitted !== otpData.hashedCode) {
      await otpRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
      const remaining = MAX_ATTEMPTS - otpData.attempts - 1;
      return res.status(400).json({
        success: false,
        error: `Incorrect OTP. ${remaining} attempt(s) remaining.`,
      });
    }

    // --- OTP is valid: atomically delete record + mark instructor as verified ---
    const batch = db.batch();
    batch.delete(otpRef);
    batch.update(db.collection('instructors').doc(uid), {
      isPhoneVerified: true,
      phoneVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return res.status(200).json({ success: true, message: 'Phone verified successfully.' });

  } catch (err) {
    if (err.code === 'auth/id-token-expired' || err.code === 'auth/invalid-id-token') {
      return res.status(401).json({ success: false, error: 'Session expired. Please login again.' });
    }
    console.error('verify-otp error:', err);
    return res.status(500).json({ success: false, error: 'An error occurred. Please try again.' });
  }
};
