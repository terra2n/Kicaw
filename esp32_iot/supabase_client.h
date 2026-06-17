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

    bool makeRequest(const char* method, const String& endpoint, const String& payload) {
        HTTPClient http;
        String url = supabaseUrl + endpoint;

        http.begin(*secureClient, url);
        http.setTimeout(5000);
        esp_task_wdt_reset();
        http.addHeader("Content-Type", "application/json");
        http.addHeader("apikey", supabaseKey);
        http.addHeader("Authorization", "Bearer " + supabaseKey);
        http.addHeader("Prefer", "return=minimal");

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
        supabaseUrl = url;
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
    bool updateRoomStatus(bool lampOn, bool motionDetected, float temperature, float humidity, int co2ppm) {
        JsonDocument doc;
        doc["lamp_status"] = lampOn;
        doc["motion_detected"] = motionDetected;
        doc["temperature_c"] = temperature;
        doc["humidity_percent"] = humidity;
        doc["co2_ppm"] = co2ppm;
        doc["updated_at"] = "now()";

        String payload;
        serializeJson(doc, payload);

        Serial.printf("[SUPABASE] Updating room_status: %s\n", payload.c_str());

        // Use UPSERT (on_conflict) to update existing record
        return makeRequest("POST", "/rest/v1/room_status?on_conflict=id", payload);
    }

    // Insert sensor log (historical data)
    bool insertSensorLog(bool lampOn, bool motionDetected, float temperature, float humidity, int co2ppm) {
        JsonDocument doc;
        doc["lamp_status"] = lampOn;
        doc["motion_detected"] = motionDetected;
        doc["temperature_c"] = temperature;
        doc["humidity_percent"] = humidity;
        doc["co2_ppm"] = co2ppm;
        doc["recorded_at"] = "now()";

        String payload;
        serializeJson(doc, payload);

        return makeRequest("POST", "/rest/v1/sensor_logs", payload);
    }

    // Insert activity log (event)
    bool insertActivityLog(const String& eventType, const String& description) {
        JsonDocument doc;
        doc["event_type"] = eventType;
        doc["description"] = description;
        doc["created_at"] = "now()";

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
