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
extern AsyncClient async_client;
extern RealtimeDatabase Database;

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
void cmdUpdateStatus(const char *status, const char *errorMsg = nullptr);
void cmdPushConfigResult(RadarConfig *cfg);
void cmdPushEngData(EngData *eng);
void cmdProcess(const String &command, const String &params);

// =========================================================================
// UPDATE STATUS DI FIREBASE
// =========================================================================
void cmdUpdateStatus(const char *status, const char *errorMsg) {
  if (!app.ready()) return;
  Database.set<String>(async_client, FB_CMD_STATUS, status);
  if (errorMsg) {
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

  // FIXED: Ditambahkan String() membungkus FB_CMD_CONFIG
  Database.set<String>(async_client, String(FB_CMD_CONFIG) + "/last_updated", String(millis()));
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

  Database.set<uint32_t>(async_client, String(FB_CMD_ENG_DATA) + "/timestamp", millis());
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

#endif // FIREBASE_CMD_H