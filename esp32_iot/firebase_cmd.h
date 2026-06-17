#ifndef FIREBASE_CMD_H
#define FIREBASE_CMD_H

#include <Arduino.h>
#include <FirebaseClient.h>
#include "ld2410_uart.h"

// =========================================================================
// FIREBASE PATHS
// =========================================================================
#define FB_RADAR_CFG     "ruangan_01/radar_config"
#define FB_CMD_PATH      FB_RADAR_CFG "/command"
#define FB_CMD_STATUS    FB_RADAR_CFG "/command_status"
#define FB_CMD_ERROR     FB_RADAR_CFG "/command_error"
#define FB_CMD_PARAMS    FB_RADAR_CFG "/command_params"
#define FB_CMD_CONFIG    FB_RADAR_CFG "/config_data"
#define FB_CMD_ENG_DATA  FB_RADAR_CFG "/engineering_data"

// =========================================================================
// EXTERNAL VARIABLES (defined in main ino)
// =========================================================================
extern FirebaseApp app;
extern AsyncClientClass async_client;
extern RealtimeDatabase Database;
extern String getTimestamp();

// =========================================================================
// STATE VARIABLES
// =========================================================================
static bool cmdProcessing = false;
static bool engineeringMode = false;
static unsigned long lastEngPush = 0;
static String lastCommand = "";
static unsigned long lastCmdCheck = 0;

// =========================================================================
// FORWARD DECLARATIONS
// =========================================================================
void cmdUpdateStatus(const char *status, const String &errorMsg = "");
void cmdPushConfigResult(RadarConfig *cfg);
void cmdPushEngData(EngData *eng);
void cmdProcess(const String &command, const String &params);
void cmdCheckFirebase();
void cmdEngineeringLoop();

// =========================================================================
// UPDATE STATUS DI FIREBASE
// =========================================================================
void cmdUpdateStatus(const char *status, const String &errorMsg) {
  if (!app.ready()) return;
  Database.set<String>(async_client, FB_CMD_STATUS, status);
  if (errorMsg.length() > 0) {
    Database.set<String>(async_client, FB_CMD_ERROR, errorMsg);
  }
}

// =========================================================================
// PUSH HASIL KONFIGURASI KE FIREBASE
// =========================================================================
void cmdPushConfigResult(RadarConfig *cfg) {
  if (!app.ready() || !cfg || !cfg->valid) return;

  Database.set<uint8_t>(async_client, String(FB_CMD_CONFIG) + "/max_moving_gate", cfg->max_moving_gate);
  Database.set<uint8_t>(async_client, String(FB_CMD_CONFIG) + "/max_stationary_gate", cfg->max_stationary_gate);
  Database.set<uint16_t>(async_client, String(FB_CMD_CONFIG) + "/inactivity_timeout", cfg->inactivity_timeout);

  for (int g = 0; g <= cfg->max_moving_gate && g < 9; g++) {
    String gPath = String(FB_CMD_CONFIG) + "/gates/g" + g;
    Database.set<uint8_t>(async_client, gPath + "/moving", cfg->moving_sens[g]);
    Database.set<uint8_t>(async_client, gPath + "/stationary", cfg->stationary_sens[g]);
  }

  Database.set<String>(async_client, String(FB_CMD_CONFIG) + "/last_updated", getTimestamp());
}

// =========================================================================
// PUSH ENGINEERING DATA KE FIREBASE
// =========================================================================
void cmdPushEngData(EngData *eng) {
  if (!app.ready() || !eng || !eng->valid) return;

  Database.set<uint16_t>(async_client, String(FB_CMD_ENG_DATA) + "/presence_distance_cm", eng->presence_distance_cm);
  Database.set<uint16_t>(async_client, String(FB_CMD_ENG_DATA) + "/moving_distance_cm", eng->moving_distance_cm);
  Database.set<uint16_t>(async_client, String(FB_CMD_ENG_DATA) + "/stationary_distance_cm", eng->stationary_distance_cm);

  for (int g = 0; g <= eng->moving_max_gate && g < 9; g++) {
    String ePath = String(FB_CMD_ENG_DATA) + "/energy/g" + g;
    Database.set<uint8_t>(async_client, ePath + "/moving", eng->moving_energy[g]);
    Database.set<uint8_t>(async_client, ePath + "/stationary", eng->stationary_energy[g]);
  }

  Database.set<String>(async_client, String(FB_CMD_ENG_DATA) + "/timestamp", getTimestamp());
}

// =========================================================================
// PUSH FIRMWARE VERSION KE FIREBASE
// =========================================================================
void cmdPushFirmware(uint8_t major, uint8_t minor, uint32_t bugfix) {
  if (!app.ready()) return;
  Database.set<uint8_t>(async_client, String(FB_CMD_CONFIG) + "/firmware_major", major);
  Database.set<uint8_t>(async_client, String(FB_CMD_CONFIG) + "/firmware_minor", minor);
  Database.set<uint32_t>(async_client, String(FB_CMD_CONFIG) + "/firmware_bugfix", bugfix);
}

// =========================================================================
// PARSE PARAMETER JSON SEDERHANA
// =========================================================================
int cmdParseIntParam(const String &json, const String &key, int defaultVal) {
  int idx = json.indexOf(key);
  if (idx == -1) return defaultVal;

  idx = json.indexOf(':', idx);
  if (idx == -1) return defaultVal;

  idx++; // skip ':'
  while (idx < (int)json.length() && (json[idx] == ' ' || json[idx] == '\t')) idx++;

  bool neg = false;
  if (json[idx] == '-') { neg = true; idx++; }

  int val = 0;
  while (idx < (int)json.length() && json[idx] >= '0' && json[idx] <= '9') {
    val = val * 10 + (json[idx] - '0');
    idx++;
  }

  return neg ? -val : val;
}

// =========================================================================
// PROSES COMMAND DARI FIREBASE
// =========================================================================
void cmdProcess(const String &command, const String &params) {
  if (command == "" || command == "none") return;

  cmdProcessing = true;
  lastCommand = command;
  cmdUpdateStatus("processing");

  Serial.print("[CMD] Processing: ");
  Serial.println(command);

  RadarConfig cfg;
  EngData eng;
  uint8_t maj = 0, min = 0;
  uint32_t bug = 0;

  if (command == "read_config") {
    if (radarBacaKonfigurasi(&cfg)) {
      cmdPushConfigResult(&cfg);
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Read config failed");
    }
  }
  else if (command == "read_firmware") {
    if (radarBacaFirmware(&maj, &min, &bug)) {
      cmdPushFirmware(maj, min, bug);
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Read firmware failed");
    }
  }
  else if (command == "set_max_gate") {
    int mGate = cmdParseIntParam(params, "moving_gate", 3);
    int sGate = cmdParseIntParam(params, "stationary_gate", 2);
    int timeout = cmdParseIntParam(params, "timeout", 5);
    if (radarSetMaxGate((uint8_t)mGate, (uint8_t)sGate, (uint16_t)timeout)) {
      delay(300);
      if (radarBacaKonfigurasi(&cfg)) cmdPushConfigResult(&cfg);
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Set max gate failed");
    }
  }
  else if (command == "set_gate_sens") {
    int gate = cmdParseIntParam(params, "gate", 0);
    int mSens = cmdParseIntParam(params, "moving", 50);
    int sSens = cmdParseIntParam(params, "stationary", 50);
    if (radarSetGateSensitivitas((uint8_t)gate, (uint8_t)mSens, (uint8_t)sSens)) {
      delay(300);
      if (radarBacaKonfigurasi(&cfg)) cmdPushConfigResult(&cfg);
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Set gate sensitivity failed");
    }
  }
  else if (command == "set_all_gates_sens") {
    uint8_t mSens[9], sSens[9];
    for (int g = 0; g < 9; g++) {
      String mKey = "m" + String(g);
      String sKey = "s" + String(g);
      mSens[g] = (uint8_t)cmdParseIntParam(params, mKey, 50);
      sSens[g] = (uint8_t)cmdParseIntParam(params, sKey, 50);
    }
    if (radarSetSemuaGateSensitivitas(mSens, sSens)) {
      delay(300);
      if (radarBacaKonfigurasi(&cfg)) cmdPushConfigResult(&cfg);
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Set all gates sensitivity failed");
    }
  }
  else if (command == "factory_reset") {
    if (radarFactoryReset()) {
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Factory reset failed");
    }
  }
  else if (command == "restart_radar") {
    if (radarRestart()) {
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Restart failed");
    }
  }
  else if (command == "engineering_on") {
    if (radarSetEngineeringMode(true)) {
      engineeringMode = true;
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Engineering mode ON failed");
    }
  }
  else if (command == "engineering_off") {
    if (radarSetEngineeringMode(false)) {
      engineeringMode = false;
      cmdUpdateStatus("done");
    } else {
      cmdUpdateStatus("error", "Engineering mode OFF failed");
    }
  }
  else {
    cmdUpdateStatus("error", String("Unknown command: ") + command);
  }

  if (app.ready()) {
    Database.set<String>(async_client, FB_CMD_PATH, "none");
  }

  cmdProcessing = false;
}

// =========================================================================
// ENGINEERING MODE LOOP
// Panggil dari loop() setiap 1 detik saat engineeringMode=true
// =========================================================================
void cmdEngineeringLoop() {
  if (!engineeringMode) return;

  unsigned long now = millis();
  if (now - lastEngPush < 1000) return;
  lastEngPush = now;

  EngData eng;
  if (radarBacaEngData(&eng)) {
    cmdPushEngData(&eng);

    Serial.print("[ENG] Presence: ");
    Serial.print(eng.presence_distance_cm);
    Serial.print("cm | Moving: ");
    Serial.print(eng.moving_distance_cm);
    Serial.print("cm | Stationary: ");
    Serial.print(eng.stationary_distance_cm);
    Serial.println("cm");
  }
}

// =========================================================================
// CHECK COMMAND DARI FIREBASE
// Panggil dari loop() setiap 500ms
// =========================================================================
void cmdCheckFirebase() {
  if (!app.ready() || cmdProcessing) return;

  static unsigned long lastPoll = 0;
  unsigned long now = millis();
  if (now - lastPoll < 500) return;
  lastPoll = now;

  String cmd = Database.get<String>(async_client, FB_CMD_PATH);
  cmd.trim();

  if (cmd.length() == 0 || cmd == "none") return;
  if (cmd == lastCommand) return;

  lastCommand = cmd;
  cmdProcessing = true;
  cmdUpdateStatus("processing");
  Serial.print("[CMD] Received: ");
  Serial.println(cmd);

  String params = Database.get<String>(async_client, FB_CMD_PARAMS);
  if (params.length() == 0) params = "{}";
  cmdProcess(cmd, params);
}

#endif // FIREBASE_CMD_H