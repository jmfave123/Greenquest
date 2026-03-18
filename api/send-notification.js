const admin = require('firebase-admin');
const https = require('https');

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

function sendOneSignal(payload, restApiKey) {
  const authorizationValue = restApiKey.startsWith('Basic ')
    ? restApiKey
    : `Basic ${restApiKey}`;

  return new Promise((resolve) => {
    const body = JSON.stringify(payload);
    const req = https.request(
      {
        hostname: 'onesignal.com',
        path: '/api/v1/notifications',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Content-Length': Buffer.byteLength(body),
          Authorization: authorizationValue,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ success: true, statusCode: res.statusCode, body: data });
          } else {
            resolve({
              success: false,
              statusCode: res.statusCode,
              error: data || 'OneSignal request failed.',
            });
          }
        });
      },
    );

    req.on('error', (error) => {
      resolve({ success: false, statusCode: 500, error: error.message });
    });

    req.write(body);
    req.end();
  });
}

function sanitizeMode(mode) {
  if (mode === 'individual' || mode === 'batch' || mode === 'group') {
    return mode;
  }
  return null;
}

function buildOneSignalPayload(body, appId) {
  const mode = sanitizeMode(body.mode);
  if (!mode) {
    return { error: 'Invalid mode. Use "individual", "batch", or "group".' };
  }

  const heading = body.heading;
  const content = body.content;
  if (!heading || !content) {
    return { error: 'heading and content are required.' };
  }

  const payload = {
    app_id: appId,
    headings: { en: String(heading) },
    contents: { en: String(content) },
  };

  if (body.bigPicture) {
    payload.big_picture = String(body.bigPicture);
  }

  if (mode === 'individual') {
    const playerId = body.playerId;
    if (!playerId || typeof playerId !== 'string') {
      return { error: 'playerId is required for individual mode.' };
    }
    payload.include_player_ids = [playerId];
  }

  if (mode === 'batch') {
    const playerIds = Array.isArray(body.playerIds)
      ? body.playerIds.filter((id) => typeof id === 'string' && id.trim().length > 0)
      : [];

    if (!playerIds.length) {
      return { error: 'playerIds must be a non-empty array for batch mode.' };
    }

    if (playerIds.length > 2000) {
      return { error: 'playerIds exceeds maximum allowed size (2000).' };
    }

    payload.include_player_ids = playerIds;

    if (body.additionalData && typeof body.additionalData === 'object') {
      payload.data = body.additionalData;
    }
  }

  if (mode === 'group') {
    const userType = body.userType;
    if (!userType || typeof userType !== 'string') {
      return { error: 'userType is required for group mode.' };
    }

    payload.filters = [
      { field: 'tag', key: 'userType', relation: '=', value: userType },
    ];
  }

  return { payload, mode };
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed.' });
  }

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'Unauthorized.' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    getDb();
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    const appId = process.env.ONESIGNAL_APP_ID;
    const restApiKey =
      process.env.ONESIGNAL_REST_API_KEY || process.env.ONESIGNAL_AUTH_KEY;

    if (!appId || !restApiKey) {
      return res.status(500).json({
        success: false,
        error: 'OneSignal server credentials are not configured.',
      });
    }

    const built = buildOneSignalPayload(req.body || {}, appId);
    if (built.error) {
      return res.status(400).json({ success: false, error: built.error });
    }

    const result = await sendOneSignal(built.payload, restApiKey);
    if (!result.success) {
      console.error('[send-notification] OneSignal request failed', {
        uid: decodedToken.uid,
        mode: built.mode,
        statusCode: result.statusCode,
      });

      return res.status(502).json({
        success: false,
        error: 'Failed to send notification through OneSignal.',
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    if (error.code === 'auth/id-token-expired' || error.code === 'auth/invalid-id-token') {
      return res.status(401).json({ success: false, error: 'Session expired. Please login again.' });
    }

    console.error('[send-notification] Unexpected error', {
      code: error.code,
      message: error.message,
    });

    return res.status(500).json({ success: false, error: 'Internal server error.' });
  }
};
