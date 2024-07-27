#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

Preferences preferences;

const char *ssid_AP = "Smart Home Automation";
const char *password_AP = "12345678";

AsyncWebServer server(80);

void setup() {
  Serial.begin(9600);

  WiFi.mode(WIFI_AP_STA);
  // Initialize preferences
  preferences.begin("my-app", false);

  // open hotspot to Wi-Fi
  WiFi.softAP(ssid_AP, password_AP);
  Serial.print("Access Point IP Address: ");
  Serial.println(WiFi.softAPIP());

  bool isWifiSet = preferences.getBool("isWifiSet", false);
  if (isWifiSet == true) {
    Serial.println("Connecting to WiFi...");
    String defaultValue = String();
    String ssid = preferences.getString("ssid", defaultValue);
    String password = preferences.getString("password", defaultValue);
    WiFi.begin(ssid, password);
    for (int i = 300; i > 0; i--) {
        if (WiFi.status() != WL_CONNECTED) {
          delay(100);
        } else {
          break;
        }
      }
      if (WiFi.status() == WL_CONNECTED) {
          Serial.println(WiFi.localIP());
        } 
  }

  // Endpoint to receive JSON data via POST
  server.on(
    "/connect_wifi", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      // Allocate JsonDocument and parse JSON data
      JsonDocument jsonDoc;
      DeserializationError error = deserializeJson(jsonDoc, (char *)data);

      if (error) {
        request->send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
        return;
      }

      // Extract values from JSON
      const char *getSSID = jsonDoc["ssid"];
      const char *getPassword = jsonDoc["password"];

      WiFi.begin(getSSID, getPassword);
      for (int i = 300; i > 0; i--) {
        if (WiFi.status() != WL_CONNECTED) {
          delay(100);
        } else {
          break;
        }
      }
      if (WiFi.status() == WL_CONNECTED) {
        preferences.clear();
        Serial.println("Connected");
        preferences.putBool("isWifiSet", true);
        preferences.putString("ssid", getSSID);
        preferences.putString("password", getPassword);
        request->send(200, "application/text", "connected");
      } else {
        request->send(500, "application/text", "unable to connect");
      }
    });

  server.begin();
}

void loop() {
}
