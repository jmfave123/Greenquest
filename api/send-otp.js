const admin = require('firebase-admin');
const https = require('https');
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
    // Use REST instead of gRPC to avoid OpenSSL 3 issues on Node 18
    admin.firestore().settings({ preferRest: true });
  }
  return admin.firestore();
}

const OTP_COLLECTION = 'otp_verifications';
const OTP_EXPIRY_MS = 5 * 60 * 1000; // 5 minutes
const COOLDOWN_MS = 60 * 1000;        // 1 minute between resends

function generateOtp() {
  // Cryptographically random 6-digit code (padded to always be 6 digits)
  const bytes = crypto.randomBytes(3);
  const num = (bytes.readUIntBE(0, 3) % 900000) + 100000;
  return num.toString();
}

function hashOtp(salt, code) {
  return crypto.createHash('sha256').update(salt + code).digest('hex');
}

function formatPhone(phone) {
  phone = phone.replace(/[\s\-\(\)]/g, '');
  if (phone.startsWith('+63')) return phone;
  if (phone.startsWith('0')) phone = phone.substring(1);
  if (!phone.startsWith('63')) phone = '63' + phone;
  const full = '+' + phone;
  return /^\+63[9]\d{9}$/.test(full) ? full : null;
}

async function sendSmsSemaphore(phone, message) {
  return new Promise((resolve) => {
    const apiKey = process.env.SEMAPHORE_API_KEY;
    if (!apiKey) {
      resolve({ success: false, error: 'SMS service not configured.' });
      return;
    }

    const params = new URLSearchParams({
      apikey: apiKey,
      number: phone,
      message: message,
      sendername: 'GreenQuest',
    });

    const body = params.toString();
    const options = {
      hostname: 'api.semaphore.co',
      path: '/api/v4/messages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode === 200 && Array.isArray(parsed) && parsed[0]?.message_id) {
            resolve({ success: true });
          } else {
            console.error('Semaphore error response:', data);
            resolve({ success: false, error: 'Failed to send SMS. Please try again.' });
          }
        } catch {
          resolve({ success: false, error: 'Invalid response from SMS service.' });
        }
      });
    });

    req.on('error', (err) => {
      console.error('Semaphore network error:', err);
      resolve({ success: false, error: 'Network error sending SMS.' });
    });

    req.write(body);
    req.end();
  });
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

    // --- Fetch instructor phone from Firestore (server is the source of truth) ---
    const instructorDoc = await db.collection('instructors').doc(uid).get();
    if (!instructorDoc.exists) {
      return res.status(404).json({ success: false, error: 'Instructor not found.' });
    }

    const phone = instructorDoc.data().phone;
    if (!phone) {
      return res.status(400).json({ success: false, error: 'Phone number not found in your profile.' });
    }

    const formattedPhone = formatPhone(phone);
    if (!formattedPhone) {
      return res.status(400).json({ success: false, error: 'Invalid phone number format in your profile.' });
    }

    // --- Enforce cooldown to prevent OTP spam ---
    const otpRef = db.collection(OTP_COLLECTION).doc(uid);
    const existing = await otpRef.get();
    if (existing.exists) {
      const createdAt = existing.data().createdAt?.toDate();
      if (createdAt && Date.now() - createdAt.getTime() < COOLDOWN_MS) {
        const remaining = Math.ceil((COOLDOWN_MS - (Date.now() - createdAt.getTime())) / 1000);
        return res.status(429).json({
          success: false,
          error: `Please wait ${remaining} seconds before requesting another OTP.`,
        });
      }
    }

    // --- Generate OTP and store hashed copy in Firestore BEFORE sending SMS ---
    const code = generateOtp();
    const salt = crypto.randomBytes(16).toString('hex');
    const hashedCode = hashOtp(salt, code);
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MS);

    await otpRef.set({
      hashedCode,
      salt,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      phone: formattedPhone,
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // --- Send SMS via Semaphore ---
    const message = `Your GreenQuest verification code is: ${code}. Valid for 5 minutes. Do not share this code.`;
    const smsResult = await sendSmsSemaphore(formattedPhone, message);

    if (!smsResult.success) {
      // Clean up OTP record if SMS fails so user can retry immediately
      await otpRef.delete();
      return res.status(500).json({ success: false, error: smsResult.error });
    }

    return res.status(200).json({ success: true, message: 'OTP sent successfully.' });

  } catch (err) {
    if (err.code === 'auth/id-token-expired' || err.code === 'auth/invalid-id-token') {
      return res.status(401).json({ success: false, error: 'Session expired. Please login again.' });
    }
    console.error('send-otp error:', err);
    return res.status(500).json({ success: false, error: 'An error occurred. Please try again.' });
  }
};
