#ifndef SUPABASE_CLIENT_H
#define SUPABASE_CLIENT_H

#include <Arduino.h>
#include <esp_task_wdt.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>

class SupabaseClient {
private:
    String supabaseUrl;
    String supabaseKey;
    WiFiClientSecure* secureClient;

    bool makeRequest(const char* method, const String& endpoint, const String& payload,
                     const String& prefer = "return=minimal") {
        HTTPClient http;
        String url = supabaseUrl + endpoint;

        http.begin(*secureClient, url);
        http.setTimeout(5000);
        esp_task_wdt_reset();
        http.addHeader("Content-Type", "application/json");
        http.addHeader("apikey", supabaseKey);
        http.addHeader("Authorization", "Bearer " + supabaseKey);
        http.addHeader("Prefer", prefer);

        int httpCode;
        if (strcmp(method, "POST") == 0) {
            httpCode = http.POST(payload);
        } else if (strcmp(method, "PATCH") == 0) {
            httpCode = http.PATCH(payload);
        } else if (strcmp(method, "PUT") == 0) {
            httpCode = http.PUT(payload);
        } else {
            http.end();
            return false;
        }

        bool success = (httpCode >= 200 && httpCode < 300);

        if (!success) {
            Serial.printf("[SUPABASE] %s %s failed: %d\n", method, endpoint.c_str(), httpCode);
            if (httpCode > 0) {
                String response = http.getString();
                Serial.printf("[SUPABASE] Response: %s\n", response.c_str());
            }
        }

        http.end();
        return success;
    }

public:
    SupabaseClient(const String& url, const String& key) {
        // [ESP-C4 fix] Normalise URL: hapus trailing slash & suffix /rest/v1
        // agar makeRequest bisa append endpoint dengan benar tanpa double-path
        String cleanUrl = url;
        if (cleanUrl.endsWith("/")) cleanUrl.remove(cleanUrl.length() - 1);
        if (cleanUrl.endsWith("/rest/v1")) cleanUrl.remove(cleanUrl.length() - 8);
        supabaseUrl = cleanUrl;
        supabaseKey = key;
        secureClient = new WiFiClientSecure();
        secureClient->setInsecure(); // Skip certificate validation (for development)
    }

    ~SupabaseClient() {
        if (secureClient) {
            delete secureClient;
        }
    }



    // Update room_status table (UPSERT - create or update)
    // Send only available sensors to avoid corrupting database aggregates
    bool updateRoomStatus(bool lampOn, bool motionDetected, float* temperature = nullptr, float* humidity = nullptr, int* co2ppm = nullptr) {
        JsonDocument doc;
        doc["id"] = 1;  // Fixed ID — room_status table has only 1 row
        doc["lamp_status"] = lampOn;
        doc["motion_detected"] = motionDetected;
        if (temperature != nullptr) doc["temperature_c"] = *temperature;
        if (humidity != nullptr) doc["humidity_percent"] = *humidity;
        if (co2ppm != nullptr) doc["co2_ppm"] = *co2ppm;

        String payload;
        serializeJson(doc, payload);

        Serial.printf("[SUPABASE] Updating room_status: %s\n", payload.c_str());

        // UPSERT: if id=1 exists then UPDATE, otherwise INSERT
        return makeRequest("POST", "/rest/v1/room_status", payload,
                           "return=minimal,resolution=merge-duplicates");
    }

    // Insert sensor log (historical data)
    bool insertSensorLog(bool lampOn, bool motionDetected, float* temperature = nullptr, float* humidity = nullptr, int* co2ppm = nullptr) {
        JsonDocument doc;
        doc["lamp_status"] = lampOn;
        doc["motion_detected"] = motionDetected;
        if (temperature != nullptr) doc["temperature_c"] = *temperature;
        if (humidity != nullptr) doc["humidity_percent"] = *humidity;
        if (co2ppm != nullptr) doc["co2_ppm"] = *co2ppm;

        String payload;
        serializeJson(doc, payload);

        return makeRequest("POST", "/rest/v1/sensor_logs", payload);
    }

    // Insert activity log (event)
    // Bug #1 fix: Removed "created_at": "now()" — DB handles it via DEFAULT NOW()
    bool insertActivityLog(const String& eventType, const String& description) {
        JsonDocument doc;
        doc["event_type"] = eventType;
        doc["description"] = description;
        // created_at tidak perlu dikirim — PostgreSQL isi otomatis via DEFAULT NOW()

        String payload;
        serializeJson(doc, payload);

        return makeRequest("POST", "/rest/v1/activity_logs", payload);
    }

    // Test connection
    bool testConnection() {
        HTTPClient http;
        String url = supabaseUrl + "/rest/v1/room_status?select=id&limit=1";

        http.begin(*secureClient, url);
        http.setTimeout(5000);
        esp_task_wdt_reset();
        http.addHeader("apikey", supabaseKey);
        http.addHeader("Authorization", "Bearer " + supabaseKey);

        int httpCode = http.GET();
        bool success = (httpCode == 200);

        if (success) {
            Serial.println("[SUPABASE] Connection test: SUCCESS");
        } else {
            Serial.printf("[SUPABASE] Connection test: FAILED (%d)\n", httpCode);
        }

        http.end();
        return success;
    }
};

#endif
