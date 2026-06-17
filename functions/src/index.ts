import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

// ─── CONFIG ───
const DAYA_LAMPU_WATT = 3.0;
const FAKTOR_EMISI_GRID = 0.85; // kg CO2/kWh (grid Indonesia)

// ─── HELPERS ───
function getDateKey(date: Date): string {
  return date.toISOString().split("T")[0]; // "2026-06-17"
}

function getMonthKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function calculateEnergyWh(durasiDetik: number): number {
  return (DAYA_LAMPU_WATT * durasiDetik) / 3600.0;
}

function calculateCO2Mg(energiWh: number): number {
  return (energiWh / 1000.0) * FAKTOR_EMISI_GRID * 1_000_000;
}

// ─── 1. ACTIVITY LOG: triggered when status_lampu changes ───
export const onLampChange = functions.database
  .ref("ruangan_01/status_lampu")
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();

    if (before === after) return null;

    const now = new Date();
    const timestamp = admin.firestore.Timestamp.fromDate(now);

    let event = "";
    let type = "";
    let whSaved = 0;
    let co2Mg = 0;

    if (before === false && after === true) {
      // Lamp turned ON
      event = "Lampu dinyalakan";
      type = "on";

      // Hitung energi yang dihemat selama lampu mati sebelumnya
      const snap = await rtdb.ref("ruangan_01/waktu_mulai_mati").once("value");
      const waktuMulaiMati = snap.val();
      if (waktuMulaiMati && typeof waktuMulaiMati === "number") {
        const durasiDetik = (Date.now() - waktuMulaiMati) / 1000;
        if (durasiDetik > 0 && durasiDetik < 86400) {
          // max 1 hari
          whSaved = calculateEnergyWh(durasiDetik);
          co2Mg = calculateCO2Mg(whSaved);
        }
      }
    } else if (before === true && after === false) {
      // Lamp turned OFF
      event = "Lampu dimatikan";
      type = "off";
    } else {
      return null;
    }

    const logEntry = {
      event,
      type,
      wh_saved: whSaved,
      co2_mg: co2Mg,
      timestamp: timestamp,
    };

    functions.logger.info("Activity log:", event, { whSaved, co2Mg });

    await db.collection("activity_logs").add(logEntry);
    return null;
  });

// ─── 2. DAILY LOG: triggered when energi_dihemat_wh changes ───
export const onEnergyUpdate = functions.database
  .ref("ruangan_01/energi_dihemat_wh")
  .onUpdate(async (change, context) => {
    const newWh = change.after.val() || 0;
    const now = new Date();
    const dateKey = getDateKey(now);
    const monthKey = getMonthKey(now);

    const co2Mg = calculateCO2Mg(newWh);
    const minutesOff = newWh > 0 ? Math.round((newWh / DAYA_LAMPU_WATT) * 60) : 0;

    // Read activity count for today
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);

    const activitySnap = await db
      .collection("activity_logs")
      .where(
        "timestamp",
        ">=",
        admin.firestore.Timestamp.fromDate(todayStart)
      )
      .where(
        "timestamp",
        "<",
        admin.firestore.Timestamp.fromDate(todayEnd)
      )
      .get();

    const sessions = activitySnap.size;

    // Update daily log
    const dailyRef = db.collection("daily_logs").doc(dateKey);
    await dailyRef.set(
      {
        date: dateKey,
        wh_saved: newWh,
        co2_mg: co2Mg,
        sessions,
        minutes_off: minutesOff,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    functions.logger.info("Daily log updated:", {
      date: dateKey,
      whSaved: newWh,
      co2Mg,
      sessions,
    });

    // Update monthly aggregate
    const monthlyRef = db.collection("monthly_logs").doc(monthKey);
    await monthlyRef.set(
      {
        month: monthKey,
        total_wh: newWh,
        total_co2: co2Mg,
        total_sessions: sessions,
        total_minutes_off: minutesOff,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return null;
  });

// ─── 3. RADAR STATUS: triggered when status_radar changes ───
export const onRadarChange = functions.database
  .ref("ruangan_01/status_radar")
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();

    if (before === after) return null;

    const now = new Date();
    const timestamp = admin.firestore.Timestamp.fromDate(now);

    let event = "";
    let type = "";

    if (before === false && after === true) {
      event = "Orang terdeteksi";
      type = "presence";
    } else if (before === true && after === false) {
      event = "Ruangan kosong";
      type = "empty";
    } else {
      return null;
    }

    const logEntry = {
      event,
      type,
      wh_saved: 0,
      co2_mg: 0,
      timestamp,
    };

    functions.logger.info("Radar event:", event);
    await db.collection("activity_logs").add(logEntry);

    return null;
  });
