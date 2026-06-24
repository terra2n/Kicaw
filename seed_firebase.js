/**
 * Firebase Data Seeder for Smart Room ECO2
 * Seeds Cloud Firestore and Realtime Database with 30 days of realistic historical data.
 * Supports both Firebase Emulator and Live Firebase production.
 */

const fs = require('fs');
const path = require('path');

// 1. Resolve firebase-admin
let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  try {
    // Try to resolve from functions directory if run from root
    admin = require(path.join(__dirname, 'functions', 'node_modules', 'firebase-admin'));
  } catch (err) {
    console.error("❌ Error: 'firebase-admin' package not found.");
    console.error("Please run 'npm install firebase-admin' or execute this script where it is installed.");
    process.exit(1);
  }
}

// 2. Load Project ID from .firebaserc
let projectId = 'kicaw-smart-room';
try {
  const rcPath = path.join(__dirname, '.firebaserc');
  if (fs.existsSync(rcPath)) {
    const rc = JSON.parse(fs.readFileSync(rcPath, 'utf8'));
    if (rc.projects && rc.projects.default) {
      projectId = rc.projects.default;
    }
  }
} catch (e) {
  console.log("⚠️ Could not read .firebaserc, using default project ID:", projectId);
}

// 3. Setup Emulator vs Production configurations
const isFirestoreEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
const isDatabaseEmulator = !!process.env.FIREBASE_DATABASE_EMULATOR_HOST;

const databaseURL = process.env.FIREBASE_DATABASE_URL || 
  (isDatabaseEmulator 
    ? `http://${process.env.FIREBASE_DATABASE_EMULATOR_HOST}?ns=${projectId}-default-rtdb`
    : `https://${projectId}-default-rtdb.firebaseio.com`);

console.log("📋 Configuration:");
console.log(`   Project ID:   ${projectId}`);
console.log(`   Database URL: ${databaseURL}`);
console.log(`   Emulators:    Firestore: ${isFirestoreEmulator ? 'YES' : 'NO'}, RTDB: ${isDatabaseEmulator ? 'YES' : 'NO'}\n`);

// Initialize Firebase Admin
if (isFirestoreEmulator || isDatabaseEmulator) {
  // Config for Emulators
  admin.initializeApp({
    projectId: projectId,
    databaseURL: databaseURL
  });
} else {
  // Config for Production
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  const os = require('os');
  const firebaseToolsPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');

  let refreshToken = process.env.FIREBASE_TOKEN;

  if (!refreshToken && fs.existsSync(firebaseToolsPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(firebaseToolsPath, 'utf8'));
      refreshToken = config.tokens && config.tokens.refresh_token;
    } catch (e) {
      console.log("⚠️ Failed to read Firebase CLI config:", e.message);
    }
  }

  if (fs.existsSync(serviceAccountPath)) {
    console.log("🔑 Using credentials from serviceAccountKey.json");
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: databaseURL
    });
  } else if (refreshToken) {
    console.log("ℹ️ Found active Firebase CLI login. Authenticating...");
    try {
      // Create a temporary JSON credentials file in the format of Application Default Credentials (ADC)
      // This is required because Firestore SDK checks and rejects admin.credential.refreshToken() directly
      const tempJson = {
        type: "authorized_user",
        client_id: "563577306548-nvd13thjj7274y12a02335133729e88d.apps.googleusercontent.com",
        client_secret: "d15444390000000000000000",
        refresh_token: refreshToken
      };
      const tempPath = path.join(os.tmpdir(), `firebase_adc_${Date.now()}.json`);
      fs.writeFileSync(tempPath, JSON.stringify(tempJson, null, 2), 'utf8');

      // Set GOOGLE_APPLICATION_CREDENTIALS environment variable so applicationDefault() loads it
      process.env.GOOGLE_APPLICATION_CREDENTIALS = tempPath;

      admin.initializeApp({
        projectId: projectId,
        credential: admin.credential.applicationDefault(),
        databaseURL: databaseURL
      });
      
      // Clean up the temp file path after initialization
      // Note: we don't delete the file immediately because Firestore might lazily read the file
      // during the first query, so we'll delete it when the process exits
      process.on('exit', () => {
        try {
          fs.unlinkSync(tempPath);
        } catch (err) {}
      });
      
      console.log("🔑 Authenticated successfully using Firebase CLI token.");
    } catch (e) {
      console.log("⚠️ Failed to authenticate using Firebase CLI token:", e.message);
      // Fallback to ADC
      console.log("ℹ️ Attempting Application Default Credentials...");
      admin.initializeApp({
        projectId: projectId,
        credential: admin.credential.applicationDefault(),
        databaseURL: databaseURL
      });
    }
  } else {
    console.log("ℹ️ No credentials found. Attempting Application Default Credentials...");
    try {
      admin.initializeApp({
        projectId: projectId,
        credential: admin.credential.applicationDefault(),
        databaseURL: databaseURL
      });
    } catch (e) {
      console.log("\n❌ Initialization failed!");
      console.log("Please do one of the following:");
      console.log("1. Run Firebase Emulators: 'firebase emulators:start'");
      console.log("2. Place your Firebase service account key in './serviceAccountKey.json'");
      console.log("3. Authenticate with Google Application Default Credentials.");
      process.exit(1);
    }
  }
}

const db = admin.firestore();
const rtdb = admin.database();

// Helper to delete all documents in a collection (Firestore)
async function deleteCollection(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(100);
  
  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();
    if (snapshot.size === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

// Seeding implementation
async function seed() {
  console.log("🧹 Cleaning up existing Firestore collections...");
  try {
    await deleteCollection("activity_logs");
    await deleteCollection("daily_logs");
    await deleteCollection("monthly_logs");
  } catch (error) {
    console.error("\n❌ Database connection or authentication failed!");
    console.error("Please ensure that:");
    console.log("1. If using emulators, make sure they are running AND you have set emulator environment variables (e.g. export FIRESTORE_EMULATOR_HOST=localhost:8080)");
    console.log("2. If using production, verify you have a valid serviceAccountKey.json file in the root directory.");
    console.log(`3. Or authenticate via Google Application Default Credentials.\n`);
    console.error("Error details:", error.message);
    process.exit(1);
  }
  console.log("✅ Firestore collections cleared\n");

  console.log("🌱 Generating 30 days of database seeds...");
  
  const dailyLogs = [];
  const monthlyLogsMap = new Map();
  const activityLogs = [];

  const DAYA_LAMPU_WATT = 3.0;
  const FAKTOR_EMISI_GRID = 0.85; // kg CO2/kWh = 850 mg CO2/Wh
  const now = new Date();

  // Loop 30 days backward
  for (let d = 30; d >= 1; d--) {
    const date = new Date(now.getTime() - d * 24 * 60 * 60 * 1000);
    const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
    const monthKey = dateKey.substring(0, 7); // YYYY-MM

    // Generate random daily Wh saved (representing lamp being turned OFF)
    // E.g., lamp is off for 8-16 hours a day -> 8 * 3W = 24Wh saved
    const whSaved = parseFloat((8.0 + Math.random() * 12.0).toFixed(2));
    const co2Mg = Math.round(whSaved * 850);
    const minutesOff = Math.round((whSaved / DAYA_LAMPU_WATT) * 60);
    const sessions = Math.floor(10 + Math.random() * 25); // Number of motion activities

    // 1. Daily log entry
    dailyLogs.push({
      date: dateKey,
      wh_saved: whSaved,
      co2_mg: co2Mg,
      minutes_off: minutesOff,
      sessions: sessions,
      updated_at: admin.firestore.Timestamp.fromDate(date)
    });

    // 2. Monthly log aggregation mapping
    if (!monthlyLogsMap.has(monthKey)) {
      monthlyLogsMap.set(monthKey, {
        month: monthKey,
        total_wh: 0,
        total_co2: 0,
        total_minutes_off: 0,
        total_sessions: 0,
        updated_at: admin.firestore.Timestamp.fromDate(date)
      });
    }
    const mLog = monthlyLogsMap.get(monthKey);
    mLog.total_wh += whSaved;
    mLog.total_co2 += co2Mg;
    mLog.total_minutes_off += minutesOff;
    mLog.total_sessions += sessions;
    mLog.updated_at = admin.firestore.Timestamp.fromDate(date); // last updated

    // 3. Activity events for this day
    const hourOffsets = [8, 10, 12, 15, 18, 20];
    hourOffsets.forEach((hour) => {
      const eventTime = new Date(date);
      eventTime.setHours(hour, Math.floor(Math.random() * 60), 0, 0);

      // Random events: motion and lamp state transitions
      const rand = Math.random();
      let event = '';
      let type = '';
      let whSavedAct = 0;
      
      if (rand < 0.3) {
        event = "Gerakan terdeteksi";
        type = "motion";
      } else if (rand < 0.65) {
        event = "Lampu dinyalakan";
        type = "on";
        // Calculate saving from the previous off duration
        whSavedAct = parseFloat((1.0 + Math.random() * 2.0).toFixed(2));
      } else {
        event = "Lampu dimatikan";
        type = "off";
      }

      activityLogs.push({
        event: event,
        type: type,
        wh_saved: whSavedAct,
        co2_mg: Math.round(whSavedAct * 850),
        timestamp: admin.firestore.Timestamp.fromDate(eventTime)
      });
    });
  }

  // 4. Batch insert Daily Logs into Firestore
  console.log(`📤 Uploading ${dailyLogs.length} daily logs to Firestore...`);
  const dailyBatch = db.batch();
  dailyLogs.forEach((log) => {
    const docRef = db.collection('daily_logs').doc(log.date);
    dailyBatch.set(docRef, log);
  });
  await dailyBatch.commit();

  // 5. Batch insert Monthly Logs into Firestore
  console.log(`📤 Uploading ${monthlyLogsMap.size} monthly logs to Firestore...`);
  const monthlyBatch = db.batch();
  monthlyLogsMap.forEach((log, month) => {
    // Format values to 2 decimals
    log.total_wh = parseFloat(log.total_wh.toFixed(2));
    log.total_co2 = Math.round(log.total_co2);
    
    const docRef = db.collection('monthly_logs').doc(month);
    monthlyBatch.set(docRef, log);
  });
  await monthlyBatch.commit();

  // 6. Batch insert Activity Logs into Firestore
  console.log(`📤 Uploading ${activityLogs.length} activity logs to Firestore...`);
  // Firestore batch has a limit of 500 operations
  for (let i = 0; i < activityLogs.length; i += 400) {
    const chunk = activityLogs.slice(i, i + 400);
    const activityBatch = db.batch();
    chunk.forEach((log) => {
      const docRef = db.collection('activity_logs').doc();
      activityBatch.set(docRef, log);
    });
    await activityBatch.commit();
  }
  console.log("✅ Firestore database successfully seeded");

  // 7. Seed Realtime Database Live Room Status
  console.log("\n📡 Seeding Firebase Realtime Database status...");
  const rtdbRef = rtdb.ref('ruangan_01');
  
  const currentStatus = {
    status_lampu: false,
    status_radar: false,
    energi_dihemat_wh: 145.28,
    co2_dicegah_mg: 123488,
    radar_distance_cm: 0,
    last_heartbeat: Math.floor(Date.now() / 1000)
  };

  await rtdbRef.set(currentStatus);
  console.log("✅ Realtime Database successfully seeded under 'ruangan_01'");
  
  console.log("\n🎉 Seeding complete! Database is fully populated with realistic test data.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌ Seeding encountered an error:", err);
  process.exit(1);
});
