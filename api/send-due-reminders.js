const admin = require('firebase-admin');
const https = require('https');

const ITEM_COLLECTIONS = [
  { collection: 'assignments', itemType: 'assignment' },
  { collection: 'activities', itemType: 'activity' },
  { collection: 'quizzes', itemType: 'quiz' },
  { collection: 'pits', itemType: 'pit' },
];

const REMINDER_WINDOWS = [
  { key: '24h', minutesBefore: 24 * 60, label: 'in 24 hours' },
  { key: '1h', minutesBefore: 60, label: 'in 1 hour' },
  { key: '15m', minutesBefore: 15, label: 'in 15 minutes' },
];

function parseBoolean(value, defaultValue = false) {
  if (value === undefined || value === null) return defaultValue;
  const normalized = String(value).toLowerCase().trim();
  return normalized === '1' || normalized === 'true' || normalized === 'yes';
}

function parsePositiveInt(value, fallback) {
  const parsed = parseInt(String(value), 10);
  if (Number.isNaN(parsed) || parsed <= 0) return fallback;
  return parsed;
}

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

function chunkArray(list, size) {
  const chunks = [];
  for (let i = 0; i < list.length; i += size) {
    chunks.push(list.slice(i, i + size));
  }
  return chunks;
}

function sendOneSignal(payload, appId, restApiKey, apiUrl) {
  const url = new URL(apiUrl || 'https://onesignal.com/api/v1/notifications');
  const authorizationValue = restApiKey.startsWith('Basic ')
    ? restApiKey
    : `Basic ${restApiKey}`;

  return new Promise((resolve) => {
    const body = JSON.stringify({
      app_id: appId,
      ...payload,
    });

    const req = https.request(
      {
        hostname: url.hostname,
        path: url.pathname,
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
            resolve({ success: true });
            return;
          }
          resolve({
            success: false,
            statusCode: res.statusCode,
            error: data || 'OneSignal request failed.',
          });
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

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value && typeof value.toDate === 'function') {
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return null;
}

function reminderEventId({ itemType, itemId, windowKey, studentId }) {
  return `${itemType}_${itemId}_${windowKey}_${studentId}`;
}

function itemTypeLabel(itemType) {
  const labels = {
    assignment: 'Assignment',
    activity: 'Activity',
    quiz: 'Quiz',
    pit: 'PIT',
  };

  return labels[itemType] || 'Item';
}

function buildReminderCopy({ itemType, title, window }) {
  const label = itemTypeLabel(itemType);

  if (window.key === 'test') {
    return {
      heading: `${label} Reminder (Test)`,
      content: `${label} "${title}" is due ${window.label}.`,
    };
  }

  return {
    heading: `${label} Due Soon`,
    content: `${label} "${title}" is due ${window.label}.`,
  };
}

async function isAuthorizedRequest(req, db) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { authorized: false, error: 'Unauthorized.' };
  }

  const bearerValue = authHeader.split('Bearer ')[1];

  const cronSecret = process.env.CRON_SECRET;
  if (cronSecret && bearerValue === cronSecret) {
    return { authorized: true, mode: 'cron' };
  }

  try {
    const decoded = await admin.auth().verifyIdToken(bearerValue);

    const email = decoded.email;
    if (!email) {
      return { authorized: false, error: 'Forbidden.' };
    }

    const adminQuery = await db
      .collection('admins')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (adminQuery.empty) {
      return { authorized: false, error: 'Forbidden. Admin access required.' };
    }

    return { authorized: true, mode: 'manual-admin', uid: decoded.uid };
  } catch (_) {
    return { authorized: false, error: 'Unauthorized.' };
  }
}

async function getStudentsForSections(db, instructorId, selectedClasses) {
  const students = new Map();
  const classes = Array.from(new Set((selectedClasses || []).map((c) => String(c).trim()).filter(Boolean)));

  if (!classes.length) return students;

  // Firestore "in" supports up to 10 values.
  const classChunks = chunkArray(classes, 10);

  for (const classChunk of classChunks) {
    const snap = await db
      .collection('users')
      .where('selectedInstructorId', '==', instructorId)
      .where('selectedSectionCode', 'in', classChunk)
      .get();

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const playerId = (data.onesignalPlayerId || '').toString().trim();
      if (!playerId) continue;
      students.set(doc.id, playerId);
    }
  }

  return students;
}

async function filterUnsentStudents(db, itemType, itemId, windowKey, studentMap) {
  const studentIds = Array.from(studentMap.keys());
  if (!studentIds.length) return [];

  const unsentStudentIds = [];
  const chunks = chunkArray(studentIds, 300);

  for (const chunk of chunks) {
    const refs = chunk.map((studentId) =>
      db
        .collection('reminder_events')
        .doc(
          reminderEventId({
            itemType,
            itemId,
            windowKey,
            studentId,
          }),
        ),
    );

    const snapshots = await db.getAll(...refs);
    for (let i = 0; i < snapshots.length; i += 1) {
      if (!snapshots[i].exists) {
        unsentStudentIds.push(chunk[i]);
      }
    }
  }

  return unsentStudentIds;
}

async function saveReminderEvents({
  db,
  itemType,
  itemId,
  itemTitle,
  instructorId,
  dueAt,
  windowKey,
  studentIds,
}) {
  const nowServerTimestamp = admin.firestore.FieldValue.serverTimestamp();
  const chunks = chunkArray(studentIds, 450);

  for (const chunk of chunks) {
    const batch = db.batch();

    for (const studentId of chunk) {
      const docRef = db
        .collection('reminder_events')
        .doc(
          reminderEventId({
            itemType,
            itemId,
            windowKey,
            studentId,
          }),
        );

      batch.set(docRef, {
        itemType,
        itemId,
        itemTitle,
        instructorId,
        studentId,
        windowKey,
        status: 'sent',
        dueAt: admin.firestore.Timestamp.fromDate(dueAt),
        sentAt: nowServerTimestamp,
      });
    }

    await batch.commit();
  }
}

async function processItemReminder({
  db,
  appId,
  restApiKey,
  oneSignalApiUrl,
  itemType,
  itemDoc,
  instructorId,
  window,
  stats,
  dryRun,
}) {
  const data = itemDoc.data() || {};
  const title = (data.title || 'Untitled').toString();
  const dueAt = toDate(data.dueDate);
  const selectedClasses = Array.isArray(data.selectedClasses) ? data.selectedClasses : [];

  if (!dueAt || !selectedClasses.length) return;

  stats.eligibleItems += 1;

  const studentMap = await getStudentsForSections(db, instructorId, selectedClasses);
  if (!studentMap.size) {
    stats.skippedNoRecipients += 1;
    return;
  }

  const unsentStudentIds = await filterUnsentStudents(
    db,
    itemType,
    itemDoc.id,
    window.key,
    studentMap,
  );

  if (!unsentStudentIds.length) {
    stats.skippedAlreadySent += 1;
    return;
  }

  const playerIds = unsentStudentIds
    .map((studentId) => studentMap.get(studentId))
    .filter(Boolean);

  if (!playerIds.length) {
    stats.skippedNoRecipients += 1;
    return;
  }

  if (dryRun) {
    stats.wouldSendStudents += unsentStudentIds.length;
    return;
  }

  const copy = buildReminderCopy({ itemType, title, window });

  const sendChunks = chunkArray(playerIds, 2000);
  for (const playerChunk of sendChunks) {
    const result = await sendOneSignal(
      {
        include_player_ids: playerChunk,
        headings: { en: copy.heading },
        contents: { en: copy.content },
        data: {
          type: 'due-reminder',
          itemType,
          itemId: itemDoc.id,
          instructorId,
          windowKey: window.key,
        },
      },
      appId,
      restApiKey,
      oneSignalApiUrl,
    );

    if (!result.success) {
      stats.failedSends += playerChunk.length;
      console.error('[send-due-reminders] Failed OneSignal send', {
        itemType,
        itemId: itemDoc.id,
        windowKey: window.key,
        statusCode: result.statusCode,
      });
      return;
    }
  }

  await saveReminderEvents({
    db,
    itemType,
    itemId: itemDoc.id,
    itemTitle: title,
    instructorId,
    dueAt,
    windowKey: window.key,
    studentIds: unsentStudentIds,
  });

  stats.sentStudents += unsentStudentIds.length;
}

module.exports = async (req, res) => {
  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed.' });
  }

  const db = getDb();
  const auth = await isAuthorizedRequest(req, db);
  if (!auth.authorized) {
    return res.status(401).json({ success: false, error: auth.error });
  }

  const appId = process.env.ONESIGNAL_APP_ID;
  const restApiKey = process.env.ONESIGNAL_REST_API_KEY || process.env.ONESIGNAL_AUTH_KEY;
  const oneSignalApiUrl = process.env.ONESIGNAL_API_URL || 'https://onesignal.com/api/v1/notifications';

  if (!appId || !restApiKey) {
    return res.status(500).json({
      success: false,
      error: 'OneSignal server credentials are not configured.',
    });
  }

  const intervalMinutes = Math.max(
    1,
    parseInt(process.env.REMINDER_CRON_INTERVAL_MINUTES || '10', 10),
  );

  const query = req.query || {};
  const body = req.body || {};
  const dryRun = parseBoolean(query.dryRun ?? body.dryRun, false);
  const testMode = parseBoolean(query.testMode ?? body.testMode, false);
  const testWindowMinutes = parsePositiveInt(
    query.testWindowMinutes ?? body.testWindowMinutes,
    120,
  );

  const activeWindows = testMode
    ? [{ key: 'test', minutesBefore: 0, label: `within ${testWindowMinutes} minutes` }]
    : REMINDER_WINDOWS;

  const now = new Date();
  const stats = {
    authorizedMode: auth.mode,
    scannedItems: 0,
    eligibleItems: 0,
    sentStudents: 0,
    wouldSendStudents: 0,
    skippedAlreadySent: 0,
    skippedNoRecipients: 0,
    failedSends: 0,
  };

  try {
    const instructorsSnap = await db.collection('instructors').get();

    for (const instructorDoc of instructorsSnap.docs) {
      const instructorId = instructorDoc.id;

      for (const itemCollection of ITEM_COLLECTIONS) {
        const subColRef = db
          .collection('instructors')
          .doc(instructorId)
          .collection(itemCollection.collection);

        for (const window of activeWindows) {
          const rangeStart = testMode
            ? new Date(now.getTime())
            : new Date(now.getTime() + window.minutesBefore * 60 * 1000);
          const rangeEnd = testMode
            ? new Date(now.getTime() + testWindowMinutes * 60 * 1000)
            : new Date(rangeStart.getTime() + intervalMinutes * 60 * 1000);

          let itemsSnap;
          try {
            itemsSnap = await subColRef
              .where('status', '==', 'active')
              .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(rangeStart))
              .where('dueDate', '<', admin.firestore.Timestamp.fromDate(rangeEnd))
              .get();
          } catch (queryErr) {
            // Fallback: broader query if composite index is not available yet.
            itemsSnap = await subColRef.where('status', '==', 'active').get();
          }

          for (const itemDoc of itemsSnap.docs) {
            const data = itemDoc.data() || {};
            const dueAt = toDate(data.dueDate);
            if (!dueAt) continue;
            if (dueAt < rangeStart || dueAt >= rangeEnd) continue;

            stats.scannedItems += 1;
            await processItemReminder({
              db,
              appId,
              restApiKey,
              oneSignalApiUrl,
              itemType: itemCollection.itemType,
              itemDoc,
              instructorId,
              window,
              stats,
              dryRun,
            });
          }
        }
      }
    }

    return res.status(200).json({
      success: true,
      now: now.toISOString(),
      intervalMinutes,
      testMode,
      testWindowMinutes,
      dryRun,
      stats,
    });
  } catch (error) {
    console.error('[send-due-reminders] Unexpected error', {
      code: error.code,
      message: error.message,
    });

    return res.status(500).json({
      success: false,
      error: 'Internal server error.',
    });
  }
};
