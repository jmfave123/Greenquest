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

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  return null;
}

function parseStaleAfterSeconds(req) {
  const raw = req.query.staleAfterSeconds;
  if (!raw) return 120;

  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed < 10 || parsed > 86400) {
    return 120;
  }

  return Math.floor(parsed);
}

function isAuthorized(req) {
  const expected = process.env.PRESENCE_CRON_SECRET || process.env.CRON_SECRET;
  if (!expected) return false;

  const tokenHeader = req.headers['x-cron-secret'];
  const bearer = req.headers.authorization;

  if (tokenHeader && tokenHeader === expected) return true;
  if (bearer && bearer === `Bearer ${expected}`) return true;

  return false;
}

async function cleanupCollection(db, collectionName, cutoffMs) {
  const snap = await db
    .collection(collectionName)
    .where('isOnline', '==', true)
    .get();

  if (snap.empty) {
    return { scanned: 0, updated: 0 };
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  let scanned = 0;
  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const lastSeenDate = toDate(data.presenceHeartbeatAt) || toDate(data.lastSeen);

    if (!lastSeenDate) {
      continue;
    }

    if (lastSeenDate.getTime() > cutoffMs) {
      continue;
    }

    batch.set(
      doc.ref,
      {
        isOnline: false,
        presenceSource: 'cron-stale-cleanup',
        updatedAt: now,
      },
      { merge: true },
    );

    updated += 1;
    batchCount += 1;

    if (batchCount >= 400) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  return { scanned, updated };
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-cron-secret');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed.' });
  }

  if (!isAuthorized(req)) {
    return res.status(401).json({ success: false, error: 'Unauthorized.' });
  }

  try {
    const db = getDb();
    const staleAfterSeconds = parseStaleAfterSeconds(req);
    const cutoffMs = Date.now() - staleAfterSeconds * 1000;

    const collections = ['users', 'instructors', 'admins'];
    const result = {};

    for (const collectionName of collections) {
      result[collectionName] = await cleanupCollection(db, collectionName, cutoffMs);
    }

    return res.status(200).json({
      success: true,
      staleAfterSeconds,
      result,
    });
  } catch (error) {
    console.error('[presence-cleanup] Unexpected error', {
      code: error.code,
      message: error.message,
    });

    return res.status(500).json({ success: false, error: 'Internal server error.' });
  }
};
