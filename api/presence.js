const admin = require('firebase-admin');

function parsePrivateKey(raw) {
  if (!raw) return '';
  return raw
    .replace(/^["']|["']$/g, '')
    .replace(/\\n/g, '\n')
    .replace(/\r\n/g, '\n')
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

async function verifyBearerToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    const error = new Error('Unauthorized.');
    error.statusCode = 401;
    throw error;
  }

  const idToken = authHeader.split('Bearer ')[1];
  return admin.auth().verifyIdToken(idToken);
}

async function findUserDocumentRef(db, uid) {
  const collections = ['users', 'instructors', 'admins'];

  for (const collectionName of collections) {
    const ref = db.collection(collectionName).doc(uid);
    const snap = await ref.get();
    if (snap.exists) {
      return { ref, collectionName };
    }
  }

  // Fallback to users collection for newly created accounts.
  return { ref: db.collection('users').doc(uid), collectionName: 'users' };
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  return null;
}

function computePresenceStatus(docData, staleAfterSeconds) {
  const now = Date.now();
  const heartbeatDate = toDate(docData.presenceHeartbeatAt);
  const lastSeenDate = toDate(docData.lastSeen);
  const sourceDate = heartbeatDate || lastSeenDate;

  if (!sourceDate) {
    return {
      isOnline: false,
      state: 'offline',
      lastSeen: null,
      activeAgoSeconds: null,
    };
  }

  const diffSeconds = Math.floor((now - sourceDate.getTime()) / 1000);
  const isStale = diffSeconds > staleAfterSeconds;

  return {
    isOnline: !isStale,
    state: isStale ? 'offline' : 'online',
    lastSeen: sourceDate.toISOString(),
    activeAgoSeconds: diffSeconds,
  };
}

function parseStaleAfterSeconds(req) {
  const raw = req.query.staleAfterSeconds;
  if (!raw) return 120;

  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed < 10 || parsed > 3600) {
    return 120;
  }

  return Math.floor(parsed);
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed.' });
  }

  try {
    const db = getDb();
    const decodedToken = await verifyBearerToken(req);
    const uid = decodedToken.uid;
    const staleAfterSeconds = parseStaleAfterSeconds(req);

    const { ref, collectionName } = await findUserDocumentRef(db, uid);

    if (req.method === 'POST') {
      const action = String((req.body && req.body.action) || 'heartbeat').toLowerCase();
      const now = admin.firestore.FieldValue.serverTimestamp();

      if (action !== 'heartbeat' && action !== 'offline') {
        return res.status(400).json({
          success: false,
          error: 'Invalid action. Use "heartbeat" or "offline".',
        });
      }

      if (action === 'heartbeat') {
        await ref.set(
          {
            isOnline: true,
            lastSeen: now,
            presenceHeartbeatAt: now,
            presenceSource: 'api-heartbeat',
            updatedAt: now,
          },
          { merge: true },
        );
      } else {
        await ref.set(
          {
            isOnline: false,
            lastSeen: now,
            presenceHeartbeatAt: now,
            presenceSource: 'api-offline',
            updatedAt: now,
          },
          { merge: true },
        );
      }
    }

    const latest = await ref.get();
    const data = latest.data() || {};
    const presence = computePresenceStatus(data, staleAfterSeconds);

    // Self-heal stale records so raw Firestore flags do not stay true forever.
    if (data.isOnline === true && presence.isOnline === false) {
      const now = admin.firestore.FieldValue.serverTimestamp();
      await ref.set(
        {
          isOnline: false,
          presenceSource: 'api-stale-correction',
          updatedAt: now,
        },
        { merge: true },
      );
    }

    return res.status(200).json({
      success: true,
      uid,
      collection: collectionName,
      staleAfterSeconds,
      isOnlineRaw: data.isOnline === true,
      presence,
    });
  } catch (error) {
    if (error.code === 'auth/id-token-expired' || error.code === 'auth/invalid-id-token') {
      return res.status(401).json({ success: false, error: 'Session expired. Please login again.' });
    }

    if (error.statusCode) {
      return res.status(error.statusCode).json({ success: false, error: error.message });
    }

    console.error('[presence] Unexpected error', {
      code: error.code,
      message: error.message,
    });

    return res.status(500).json({ success: false, error: 'Internal server error.' });
  }
};
