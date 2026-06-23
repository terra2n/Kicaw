"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onRadarChange = exports.onEnergyUpdate = exports.onLampChange = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const rtdb = admin.database();
// ─── CONFIG ───
const DAYA_LAMPU_WATT = 3.0;
const FAKTOR_EMISI_GRID = 0.85; // kg CO2/kWh (grid Indonesia)
// ─── HELPERS ───
// [BACK-H5 fix] Gunakan WIB (UTC+7) bukan UTC agar daily log tidak masuk tanggal kemarin
// setelah jam 17:00 WIB (= 10:00 UTC)
function toWIB(date) {
    return new Date(date.getTime() + 7 * 60 * 60 * 1000);
}
function getDateKey(date) {
    return toWIB(date).toISOString().split("T")[0]; // "2026-06-17" dalam WIB
}
function getMonthKey(date) {
    const wib = toWIB(date);
    return `${wib.getFullYear()}-${String(wib.getMonth() + 1).padStart(2, "0")}`;
}
function calculateEnergyWh(durasiDetik) {
    return (DAYA_LAMPU_WATT * durasiDetik) / 3600.0;
}
function calculateCO2Mg(energiWh) {
    return (energiWh / 1000.0) * FAKTOR_EMISI_GRID * 1000000;
}
// ─── 1. ACTIVITY LOG: triggered when status_lampu changes ───
exports.onLampChange = functions.database
    .ref("ruangan_01/status_lampu")
    .onUpdate(async (change, context) => {
    // [BACK-H1 fix] Wrap seluruh logic dalam try/catch agar error ter-log
    try {
        const before = change.before.val();
        const after = change.after.val();
        if (before === after)
            return null;
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
        }
        else if (before === true && after === false) {
            // Lamp turned OFF
            event = "Lampu dimatikan";
            type = "off";
        }
        else {
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
    }
    catch (err) {
        functions.logger.error("[onLampChange] Unhandled error:", err);
        return null;
    }
});
// ─── 2. DAILY LOG: triggered when energi_dihemat_wh changes ───
exports.onEnergyUpdate = functions.database
    .ref("ruangan_01/energi_dihemat_wh")
    .onUpdate(async (change, context) => {
    // [BACK-H1 fix] Wrap seluruh logic dalam try/catch
    try {
        const newWh = change.after.val() || 0;
        const now = new Date();
        const dateKey = getDateKey(now); // [BACK-H5 fix] WIB
        const monthKey = getMonthKey(now); // [BACK-H5 fix] WIB
        const co2Mg = calculateCO2Mg(newWh);
        const minutesOff = newWh > 0 ? Math.round((newWh / DAYA_LAMPU_WATT) * 60) : 0;
        // Read activity count for today
        const todayStart = new Date(toWIB(now).getFullYear(), toWIB(now).getMonth(), toWIB(now).getDate());
        const todayEnd = new Date(todayStart);
        todayEnd.setDate(todayEnd.getDate() + 1);
        const activitySnap = await db
            .collection("activity_logs")
            .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(todayStart))
            .where("timestamp", "<", admin.firestore.Timestamp.fromDate(todayEnd))
            .get();
        const sessions = activitySnap.size;
        // Update daily log
        const dailyRef = db.collection("daily_logs").doc(dateKey);
        await dailyRef.set({
            date: dateKey,
            wh_saved: newWh,
            co2_mg: co2Mg,
            sessions,
            minutes_off: minutesOff,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        functions.logger.info("Daily log updated:", {
            date: dateKey,
            whSaved: newWh,
            co2Mg,
            sessions,
        });
        // [BACK-H2 fix] Hitung total bulan ini secara kumulatif dari semua daily_logs
        // Sebelumnya: monthly di-set dengan newWh saja → total bulan = nilai hari terakhir
        const wib = toWIB(now);
        const monthStart = `${wib.getFullYear()}-${String(wib.getMonth() + 1).padStart(2, "0")}-01`;
        const nextMonth = new Date(wib.getFullYear(), wib.getMonth() + 1, 1);
        const monthEnd = `${nextMonth.getFullYear()}-${String(nextMonth.getMonth() + 1).padStart(2, "0")}-01`;
        const monthSnap = await db
            .collection("daily_logs")
            .where("date", ">=", monthStart)
            .where("date", "<", monthEnd)
            .get();
        let monthlyWh = 0;
        let monthlyCo2 = 0;
        let monthlySessions = 0;
        let monthlyMinutes = 0;
        monthSnap.forEach((doc) => {
            const d = doc.data();
            monthlyWh += d.wh_saved || 0;
            monthlyCo2 += d.co2_mg || 0;
            monthlySessions += d.sessions || 0;
            monthlyMinutes += d.minutes_off || 0;
        });
        // Update monthly aggregate (kumulatif semua hari bulan ini)
        const monthlyRef = db.collection("monthly_logs").doc(monthKey);
        await monthlyRef.set({
            month: monthKey,
            total_wh: monthlyWh,
            total_co2: monthlyCo2,
            total_sessions: monthlySessions,
            total_minutes_off: monthlyMinutes,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        functions.logger.info("Monthly log updated:", {
            month: monthKey,
            totalWh: monthlyWh,
            totalCo2: monthlyCo2,
            totalSessions: monthlySessions,
        });
        return null;
    }
    catch (err) {
        functions.logger.error("[onEnergyUpdate] Unhandled error:", err);
        return null;
    }
});
// ─── 3. RADAR STATUS: triggered when status_radar changes ───
exports.onRadarChange = functions.database
    .ref("ruangan_01/status_radar")
    .onUpdate(async (change, context) => {
    // [BACK-H1 fix] Wrap seluruh logic dalam try/catch
    try {
        const before = change.before.val();
        const after = change.after.val();
        if (before === after)
            return null;
        const now = new Date();
        const timestamp = admin.firestore.Timestamp.fromDate(now);
        let event = "";
        let type = "";
        if (before === false && after === true) {
            event = "Orang terdeteksi";
            type = "presence";
        }
        else if (before === true && after === false) {
            event = "Ruangan kosong";
            type = "empty";
        }
        else {
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
    }
    catch (err) {
        functions.logger.error("[onRadarChange] Unhandled error:", err);
        return null;
    }
});
//# sourceMappingURL=index.js.map