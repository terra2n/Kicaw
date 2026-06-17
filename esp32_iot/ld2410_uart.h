#ifndef LD2410_UART_H
#define LD2410_UART_H

#include <Arduino.h>

// =========================================================================
// PIN DEFINITION
// =========================================================================
#define PIN_RADAR_RX 17
#define PIN_RADAR_TX 16
#define UART_BAUD    256000

// =========================================================================
// FRAME COMMAND MACROS (HLK-LD2410C Protocol)
// =========================================================================
// Enable config mode
static const uint8_t CMD_ENABLE_CONFIG[]   = {0xFD,0xFC,0xFB,0xFA,0x04,0x00,0xFF,0x00,0x01,0x00,0x04,0x03,0x02,0x01};
// End config mode
static const uint8_t CMD_END_CONFIG[]      = {0xFD,0xFC,0xFB,0xFA,0x02,0x00,0xFE,0x00,0x04,0x03,0x02,0x01};
// Read configuration
static const uint8_t CMD_READ_CONFIG[]     = {0xFD,0xFC,0xFB,0xFA,0x00,0x00,0x61,0x00,0x04,0x03,0x02,0x01};
// Write configuration (base frame, data appended)
static const uint8_t CMD_WRITE_CONFIG[]    = {0xFD,0xFC,0xFB,0xFA,0x00,0x00,0x60,0x00,0x04,0x03,0x02,0x01};
// Read firmware version
static const uint8_t CMD_READ_FIRMWARE[]   = {0xFD,0xFC,0xFB,0xFA,0x00,0x00,0x70,0x00,0x04,0x03,0x02,0x01};
// Factory reset
static const uint8_t CMD_FACTORY_RESET[]   = {0xFD,0xFC,0xFB,0xFA,0x00,0x00,0x62,0x00,0x04,0x03,0x02,0x01};
// Restart
static const uint8_t CMD_RESTART[]         = {0xFD,0xFC,0xFB,0xFA,0x00,0x00,0x64,0x00,0x04,0x03,0x02,0x01};
// Engineering mode ON
static const uint8_t CMD_ENG_MODE_ON[]     = {0xFD,0xFC,0xFB,0xFA,0x01,0x00,0x63,0x00,0x01,0x00,0x04,0x03,0x02,0x01};
// Engineering mode OFF
static const uint8_t CMD_ENG_MODE_OFF[]    = {0xFD,0xFC,0xFB,0xFA,0x01,0x00,0x63,0x00,0x00,0x00,0x04,0x03,0x02,0x01};

// =========================================================================
// DATA STRUCTURES
// =========================================================================

struct RadarConfig {
  uint8_t max_moving_gate;        // 0-9
  uint8_t max_stationary_gate;    // 0-9
  uint16_t inactivity_timeout;    // seconds
  uint8_t moving_sens[9];        // per gate sensitivity 0-100 (indices 0-8)
  uint8_t stationary_sens[9];    // per gate sensitivity 0-100
  bool valid;
};

struct EngData {
  uint16_t presence_distance_cm;   // 0 = no presence
  uint16_t moving_distance_cm;
  uint16_t stationary_distance_cm;
  uint8_t moving_energy[9];        // energy 0-100 per gate
  uint8_t stationary_energy[9];    // energy 0-100 per gate
  uint8_t moving_max_gate;
  uint8_t stationary_max_gate;
  bool valid;
};

// =========================================================================
// PERSISTENT UART INSTANCE
// =========================================================================
static HardwareSerial RadarSerial(2);

static void radarInit() {
  RadarSerial.begin(UART_BAUD, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  delay(200);
  while (RadarSerial.available()) RadarSerial.read();
  Serial.println("[RADAR] UART initialized (persistent)");
}

// =========================================================================
// LOW-LEVEL: Send raw bytes and read response (uses persistent UART)
// =========================================================================

static bool radarRawCommand(const uint8_t cmd[], size_t cmdLen,
                             uint8_t resp[], size_t *respLen,
                             unsigned long timeoutMs = 500) {
  while (RadarSerial.available()) RadarSerial.read();

  RadarSerial.write(cmd, cmdLen);
  RadarSerial.flush();

  *respLen = 0;
  unsigned long start = millis();
  while (millis() - start < timeoutMs && *respLen < 256) {
    if (RadarSerial.available()) {
      resp[(*respLen)++] = RadarSerial.read();
    }
  }

  if (*respLen >= 4) {
    Serial.print("[UART] Response "); Serial.print(*respLen); Serial.println(" bytes");
    return true;
  }
  Serial.println("[UART] No response from radar");
  return false;
}

// =========================================================================
// HIGH-LEVEL FUNCTIONS
// =========================================================================

/**
 * Baca konfigurasi lengkap radar.
 * Parse response dari command Read Config (0x61).
 */
bool radarBacaKonfigurasi(RadarConfig *cfg) {
  if (!cfg) return false;
  cfg->valid = false;

  Serial.println("[RADAR] Reading configuration...");

  // Enable config mode
  uint8_t enableResp[256]; size_t enableLen = 0;
  if (!radarRawCommand(CMD_ENABLE_CONFIG, sizeof(CMD_ENABLE_CONFIG),
                        enableResp, &enableLen, 300)) {
    Serial.println("[RADAR] Failed to enter config mode");
    return false;
  }

  delay(100);

  // Send read config command
  uint8_t readResp[256]; size_t readLen = 0;
  if (!radarRawCommand(CMD_READ_CONFIG, sizeof(CMD_READ_CONFIG),
                        readResp, &readLen, 500)) {
    Serial.println("[RADAR] Read config: no response");
    uint8_t endResp[64]; size_t endLen = 0;
    radarRawCommand(CMD_END_CONFIG, sizeof(CMD_END_CONFIG), endResp, &endLen, 200);
    return false;
  }

  // Send end config mode
  uint8_t endResp[64]; size_t endLen = 0;
  radarRawCommand(CMD_END_CONFIG, sizeof(CMD_END_CONFIG), endResp, &endLen, 200);

  // Verify response
  if (readLen < 20 || readResp[0] != 0xFD || readResp[1] != 0xFC ||
      readResp[2] != 0xFB || readResp[3] != 0xFA) {
    Serial.println("[RADAR] Invalid response");
    return false;
  }

  if (readResp[6] != 0x61) {
    Serial.print("[RADAR] Unexpected cmd: 0x"); Serial.println(readResp[6], HEX);
    return false;
  }

  // Parse data (starting at offset 8)
  cfg->max_moving_gate      = readResp[8];
  cfg->max_stationary_gate  = readResp[9];
  cfg->inactivity_timeout   = readResp[10] | (readResp[11] << 8);

  Serial.print("[RADAR] Max moving gate: ");   Serial.println(cfg->max_moving_gate);
  Serial.print("[RADAR] Max stationary gate: "); Serial.println(cfg->max_stationary_gate);
  Serial.print("[RADAR] Inactivity timeout: ");  Serial.println(cfg->inactivity_timeout);

  // Parse gate sensitivity pairs (triplets: gate_idx, moving_sens, stationary_sens)
  uint8_t offset = 12;
  uint8_t gateCount = 0;

  while (offset + 2 < readLen && gateCount <= 8) {
    uint8_t gateIdx = readResp[offset];
    if (gateIdx <= 8) {
      cfg->moving_sens[gateIdx]     = readResp[offset + 1];
      cfg->stationary_sens[gateIdx] = readResp[offset + 2];
      Serial.print("[RADAR] Gate "); Serial.print(gateIdx);
      Serial.print(": M="); Serial.print(cfg->moving_sens[gateIdx]);
      Serial.print(" S="); Serial.println(cfg->stationary_sens[gateIdx]);
      gateCount++;
      offset += 3;
    } else {
      offset++;
    }
  }

  cfg->valid = true;
  Serial.println("[RADAR] Configuration read successfully");
  return true;
}

/**
 * Set max distance gates dan inactivity timeout.
 */
bool radarSetMaxGate(uint8_t movingGate, uint8_t stationaryGate,
                      uint16_t timeoutDetik) {
  Serial.println("[RADAR] Setting max gate...");

  uint8_t cmd[] = {
    0xFD, 0xFC, 0xFB, 0xFA,  // header
    0x14, 0x00,              // data length = 20
    0x60, 0x00,              // write config command
    movingGate, 0x00,        // max moving gate + reserved
    stationaryGate, 0x00,    // max stationary gate + reserved
    (uint8_t)(timeoutDetik & 0xFF),
    (uint8_t)((timeoutDetik >> 8) & 0xFF),  // timeout LE
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // reserved 8 bytes
    0x04, 0x03, 0x02, 0x01   // tail
  };

  // Enable config
  uint8_t enableResp[64]; size_t enableLen = 0;
  radarRawCommand(CMD_ENABLE_CONFIG, sizeof(CMD_ENABLE_CONFIG),
                  enableResp, &enableLen, 300);
  delay(100);

  // Send write
  uint8_t writeResp[128]; size_t writeLen = 0;
  bool ok = radarRawCommand(cmd, sizeof(cmd), writeResp, &writeLen, 500);

  // End config
  uint8_t endResp[64]; size_t endLen = 0;
  radarRawCommand(CMD_END_CONFIG, sizeof(CMD_END_CONFIG), endResp, &endLen, 200);

  if (ok && writeLen >= 10 && writeResp[6] == 0x60 && writeResp[8] == 0x00) {
    Serial.println("[RADAR] Max gate set successfully");
    return true;
  }
  Serial.println("[RADAR] Failed to set max gate");
  return false;
}

/**
 * Set sensitivitas untuk satu gate tertentu (0-100).
 */
bool radarSetGateSensitivitas(uint8_t gate, uint8_t movingSens,
                               uint8_t stationarySens) {
  if (gate > 8 || movingSens > 100 || stationarySens > 100) {
    Serial.println("[RADAR] Invalid sensitivity params");
    return false;
  }

  Serial.print("[RADAR] Set gate "); Serial.print(gate);
  Serial.print(" M="); Serial.print(movingSens);
  Serial.print(" S="); Serial.println(stationarySens);

  uint8_t cmd[] = {
    0xFD, 0xFC, 0xFB, 0xFA,  // header
    0x06, 0x00,              // data length = 6
    0x60, 0x00,              // write config
    gate, movingSens, stationarySens, 0x00,  // gate data + reserved
    0x04, 0x03, 0x02, 0x01   // tail
  };

  uint8_t enableResp[64]; size_t enableLen = 0;
  radarRawCommand(CMD_ENABLE_CONFIG, sizeof(CMD_ENABLE_CONFIG),
                  enableResp, &enableLen, 300);
  delay(100);

  uint8_t writeResp[128]; size_t writeLen = 0;
  bool ok = radarRawCommand(cmd, sizeof(cmd), writeResp, &writeLen, 500);

  uint8_t endResp[64]; size_t endLen = 0;
  radarRawCommand(CMD_END_CONFIG, sizeof(CMD_END_CONFIG), endResp, &endLen, 200);

  if (ok && writeLen >= 10 && writeResp[6] == 0x60 && writeResp[8] == 0x00) {
    Serial.println("[RADAR] Sensitivity set OK");
    return true;
  }
  Serial.println("[RADAR] Set sensitivity failed");
  return false;
}

/**
 * Set sensitivitas untuk SEMUA gate sekaligus.
 */
bool radarSetSemuaGateSensitivitas(const uint8_t movingSens[9],
                                    const uint8_t stationarySens[9]) {
  Serial.println("[RADAR] Setting all gate sensitivities...");

  uint8_t cmd[64];
  size_t idx = 0;

  cmd[idx++] = 0xFD; cmd[idx++] = 0xFC; cmd[idx++] = 0xFB; cmd[idx++] = 0xFA;
  cmd[idx++] = 0x00; cmd[idx++] = 0x00; // data length placeholder
  cmd[idx++] = 0x60; cmd[idx++] = 0x00; // write config

  uint8_t dataStart = idx;
  for (uint8_t g = 0; g <= 8; g++) {
    cmd[idx++] = g;
    cmd[idx++] = movingSens[g];
    cmd[idx++] = stationarySens[g];
  }

  cmd[4] = idx - dataStart;  // data length
  cmd[5] = 0x00;

  cmd[idx++] = 0x04; cmd[idx++] = 0x03; cmd[idx++] = 0x02; cmd[idx++] = 0x01;

  uint8_t enableResp[64]; size_t enableLen = 0;
  radarRawCommand(CMD_ENABLE_CONFIG, sizeof(CMD_ENABLE_CONFIG),
                  enableResp, &enableLen, 300);
  delay(150);

  uint8_t writeResp[128]; size_t writeLen = 0;
  bool ok = radarRawCommand(cmd, idx, writeResp, &writeLen, 500);

  uint8_t endResp[64]; size_t endLen = 0;
  radarRawCommand(CMD_END_CONFIG, sizeof(CMD_END_CONFIG), endResp, &endLen, 200);

  if (ok && writeLen >= 10 && writeResp[6] == 0x60 && writeResp[8] == 0x00) {
    Serial.println("[RADAR] All gates configured OK");
    return true;
  }
  Serial.println("[RADAR] Failed to configure all gates");
  return false;
}

/**
 * Baca versi firmware radar.
 */
bool radarBacaFirmware(uint8_t *major, uint8_t *minor, uint32_t *bugfix) {
  Serial.println("[RADAR] Reading firmware version...");

  uint8_t resp[128]; size_t respLen = 0;
  if (!radarRawCommand(CMD_READ_FIRMWARE, sizeof(CMD_READ_FIRMWARE),
                        resp, &respLen, 500)) {
    return false;
  }

  if (respLen >= 14 && resp[0] == 0xFD && resp[6] == 0x70) {
    *major = resp[8];
    *minor = resp[9];
    *bugfix = (resp[10] << 16) | (resp[11] << 8) | resp[12];
    Serial.print("[RADAR] Firmware v");
    Serial.print(*major); Serial.print(".");
    Serial.print(*minor); Serial.print(".");
    Serial.println(*bugfix, HEX);
    return true;
  }
  Serial.println("[RADAR] Failed to read firmware");
  return false;
}

/**
 * Aktifkan/nonaktifkan engineering mode.
 */
bool radarSetEngineeringMode(bool enable) {
  Serial.print("[RADAR] Engineering mode: ");
  Serial.println(enable ? "ON" : "OFF");

  const uint8_t *cmd = enable ? CMD_ENG_MODE_ON : CMD_ENG_MODE_OFF;
  size_t cmdLen = enable ? sizeof(CMD_ENG_MODE_ON) : sizeof(CMD_ENG_MODE_OFF);

  uint8_t resp[128]; size_t respLen = 0;
  bool ok = radarRawCommand(cmd, cmdLen, resp, &respLen, 500);

  if (ok && respLen >= 10 && resp[6] == 0x63 && resp[8] == 0x00) {
    Serial.println("[RADAR] Engineering mode toggled OK");
    return true;
  }
  Serial.println("[RADAR] Engineering mode toggle failed");
  return false;
}

/**
 * Baca data engineering mode dari radar.
 * Radar mengirim data terus-menerus dalam mode ini.
 * Panggil setiap 50-100ms di loop saat engineering mode aktif.
 */
bool radarBacaEngData(EngData *data) {
  if (!data) return false;
  data->valid = false;

  while (RadarSerial.available()) RadarSerial.read();

  unsigned long start = millis();
  uint8_t buf[128];
  size_t len = 0;

  while (millis() - start < 100 && len < sizeof(buf)) {
    if (RadarSerial.available()) buf[len++] = RadarSerial.read();
  }

  // Parse: FD FC FB FA [len] 00 63 00 [data...] 04 03 02 01
  for (size_t i = 0; i + 12 < len; i++) {
    if (buf[i]==0xFD && buf[i+1]==0xFC && buf[i+2]==0xFB && buf[i+3]==0xFA) {
      if (buf[i+6]==0x63 && buf[i+7]==0x00) {
        uint8_t dLen = buf[i+4];
        uint8_t *d = &buf[i+8];

        if (dLen >= 8) {
          data->presence_distance_cm   = d[0] | (d[1] << 8);
          data->moving_max_gate        = d[2];
          data->stationary_max_gate     = d[3];
          data->moving_distance_cm      = d[4] | (d[5] << 8);
          data->stationary_distance_cm  = d[6] | (d[7] << 8);

          for (uint8_t g = 0; g <= data->moving_max_gate && g < 9; g++) {
            uint8_t ei = 8 + g * 2;
            if (ei + 1 < dLen) {
              data->moving_energy[g]     = d[ei];
              data->stationary_energy[g] = d[ei + 1];
            }
          }
          data->valid = true;
          return true;
        }
      }
    }
  }
  return false;
}

/**
 * Factory reset radar.
 */
bool radarFactoryReset() {
  Serial.println("[RADAR] Factory reset...");
  uint8_t resp[128]; size_t respLen = 0;
  bool ok = radarRawCommand(CMD_FACTORY_RESET, sizeof(CMD_FACTORY_RESET),
                               resp, &respLen, 1000);
  if (ok && respLen >= 10) {
    Serial.println("[RADAR] Factory reset accepted");
    return true;
  }
  Serial.println("[RADAR] Factory reset failed");
  return false;
}

/**
 * Restart radar.
 */
bool radarRestart() {
  Serial.println("[RADAR] Restarting...");
  uint8_t resp[128]; size_t respLen = 0;
  bool ok = radarRawCommand(CMD_RESTART, sizeof(CMD_RESTART),
                               resp, &respLen, 1000);
  if (ok) Serial.println("[RADAR] Restart command sent");
  return ok;
}

#endif // LD2410_UART_H
