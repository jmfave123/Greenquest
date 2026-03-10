const admin = require('firebase-admin');

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

    // --- Check email is actually verified in Firebase Auth (source of truth) ---
    const userRecord = await admin.auth().getUser(uid);
    if (!userRecord.emailVerified) {
      return res.status(400).json({
        success: false,
        error: 'Email not yet verified. Please click the link in your email.',
      });
    }

    // --- Update instructor document in Firestore ---
    const instructorRef = db.collection('instructors').doc(uid);
    const instructorDoc = await instructorRef.get();

    if (!instructorDoc.exists) {
      return res.status(404).json({ success: false, error: 'Instructor not found.' });
    }

    await instructorRef.update({
      isEmailVerified: true,
      emailVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('verify-email error:', error);

    if (error.code === 'auth/argument-error' || error.code === 'auth/id-token-expired') {
      return res.status(401).json({ success: false, error: 'Invalid or expired token.' });
    }

    return res.status(500).json({ success: false, error: 'Internal server error.' });
  }
};
