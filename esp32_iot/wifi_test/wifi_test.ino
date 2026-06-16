#include <Arduino.h>
#include <WiFi.h>

const char* WIFI_SSID = "KucingGanas";
const char* WIFI_PASSWORD = "kucing22";

unsigned long lastRetry = 0;
const unsigned long RETRY_INTERVAL_MS = 15000;

void onWiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_READY:
      Serial.println("[WIFI] READY");
      break;
    case ARDUINO_EVENT_WIFI_STA_START:
      Serial.println("[WIFI] STA START");
      break;
    case ARDUINO_EVENT_WIFI_STA_CONNECTED:
      Serial.println("[WIFI] CONNECTED TO AP");
      break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("[WIFI] GOT IP: ");
      Serial.println(WiFi.localIP());
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("[WIFI] DISCONNECTED");
      break;
    default:
      Serial.print("[WIFI] EVENT: ");
      Serial.println((int)event);
      break;
  }
}

bool connectWiFi(unsigned long timeoutMs = 15000) {
  WiFi.disconnect(true, true);
  delay(200);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to Wi-Fi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < timeoutMs) {
    Serial.print('.');
    delay(300);
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("[OK] WiFi connected");
    Serial.print("SSID: ");
    Serial.println(WIFI_SSID);
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("RSSI: ");
    Serial.println(WiFi.RSSI());
    return true;
  }

  wl_status_t status = WiFi.status();
  Serial.print("[FAIL] WiFi status: ");
  Serial.println((int)status);

  int n = WiFi.scanNetworks();
  bool found = false;
  for (int i = 0; i < n; i++) {
    if (WiFi.SSID(i) == WIFI_SSID) {
      found = true;
      Serial.print("[SCAN] Found SSID: ");
      Serial.print(WiFi.SSID(i));
      Serial.print(" | RSSI: ");
      Serial.println(WiFi.RSSI(i));
      break;
    }
  }

  if (!found) {
    Serial.println("[SCAN] SSID not found");
    Serial.println("[HINT] Hotspot name not visible or not on 2.4GHz.");
  } else {
    Serial.println("[HINT] SSID visible, but connection failed.");
    Serial.println("[HINT] Check if password is correct.");
  }

  if (status == WL_CONNECT_FAILED) {
    Serial.println("[ERROR] Password/auth failed.");
  } else if (status == WL_NO_SSID_AVAIL) {
    Serial.println("[ERROR] SSID not available.");
  } else {
    Serial.println("[ERROR] Unknown WiFi issue.");
  }

  WiFi.scanDelete();
  return false;
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  WiFi.onEvent(onWiFiEvent);
  Serial.println();
  Serial.println("=== ESP32 WiFi Test ===");
  Serial.println("This sketch only tests WiFi connection.");
  Serial.print("Target SSID: ");
  Serial.println(WIFI_SSID);
  connectWiFi();
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    static unsigned long lastInfo = 0;
    if (millis() - lastInfo >= 10000) {
      lastInfo = millis();
      Serial.print("[INFO] Still connected | IP: ");
      Serial.print(WiFi.localIP());
      Serial.print(" | RSSI: ");
      Serial.println(WiFi.RSSI());
    }
  } else {
    if (millis() - lastRetry >= RETRY_INTERVAL_MS) {
      lastRetry = millis();
      Serial.println("[INFO] Retrying WiFi...");
      connectWiFi();
    }
  }
  delay(100);
}
