const admin = require('firebase-admin');
const https = require('https');

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
    admin.firestore().settings({ preferRest: true });
  }
  return admin.firestore();
}

/**
 * Send an email via the EmailJS REST API (server-side).
 * Docs: https://www.emailjs.com/docs/rest-api/send/
 */
function sendEmail({ toEmail, toName, action }) {
  return new Promise((resolve) => {
    const serviceId  = process.env.EMAILJS_SERVICE_ID;
    const publicKey  = process.env.EMAILJS_PUBLIC_KEY;
    const privateKey = process.env.EMAILJS_PRIVATE_KEY;

    const templateId =
      action === 'approved'
        ? process.env.EMAILJS_TEMPLATE_APPROVED_ID
        : process.env.EMAILJS_TEMPLATE_REJECTED_ID;

    if (!serviceId || !templateId || !publicKey || !privateKey) {
      resolve({ success: false, error: 'EmailJS is not configured.' });
      return;
    }

    const payload = JSON.stringify({
      service_id: serviceId,
      template_id: templateId,
      user_id: publicKey,
      accessToken: privateKey,
      template_params: {
        to_email: toEmail,
        to_name: toName,
        status: action === 'approved' ? 'Approved' : 'Rejected',
        app_name: 'GreenQuest',
      },
    });

    const options = {
      hostname: 'api.emailjs.com',
      path: '/api/v1.0/email/send',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
        'origin': 'https://greenquest-seven.vercel.app',
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve({ success: true });
        } else {
          resolve({ success: false, error: `EmailJS error ${res.statusCode}: ${data}` });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.write(payload);
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
    // --- Authenticate the request (must be a signed-in admin) ---
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'Unauthorized.' });
    }
 
    const idToken = authHeader.split('Bearer ')[1];
    const db = getDb();
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const callerEmail = decodedToken.email;

    // Verify the caller is an admin
    const adminQuery = await db
      .collection('admins')
      .where('email', '==', callerEmail)
      .limit(1)
      .get();

    if (adminQuery.empty) {
      return res.status(403).json({ success: false, error: 'Forbidden. Admin access required.' });
    }

    // --- Validate request body ---
    const { instructorId, action } = req.body || {};

    if (!instructorId || typeof instructorId !== 'string') {
      return res.status(400).json({ success: false, error: 'instructorId is required.' });
    }
    if (action !== 'approved' && action !== 'rejected') {
      return res.status(400).json({ success: false, error: 'action must be "approved" or "rejected".' });
    }

    // --- Fetch instructor data from Firestore ---
    const instructorDoc = await db.collection('instructors').doc(instructorId).get();

    if (!instructorDoc.exists) {
      return res.status(404).json({ success: false, error: 'Instructor not found.' });
    }

    const data = instructorDoc.data();
    const toEmail = data.email || data.emailAddress;
    const toName  = [data.firstName, data.lastName].filter(Boolean).join(' ') || data.name || 'Instructor';

    if (!toEmail) {
      return res.status(400).json({ success: false, error: 'Instructor has no email address on record.' });
    }

    // --- Send the email via Resend ---
    const result = await sendEmail({ toEmail, toName, action });

    if (!result.success) {
      console.error('[notify-instructor] Resend error:', result.error); 
      return res.status(502).json({ success: false, error: result.error });
    }  

    return res.status(200).json({ success: true, message: `Notification email sent to ${toEmail}.` });
  } catch (err) {
    console.error('[notify-instructor] Unexpected error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error.' });
  }
};
