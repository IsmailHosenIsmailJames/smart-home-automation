#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <Wire.h>
#include <Adafruit_BMP280.h>
#include <Adafruit_AHTX0.h>  // Replace with appropriate AHT20 library

Adafruit_AHTX0 aht;
Adafruit_BMP280 bmp;

Preferences preferences;

const char *ssid_AP = "Smart Home Automation";
const char *password_AP = "12345678";

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP);

AsyncWebServer server(80);

void setup() {
  Wire.begin(1, 2);  // SDA, SCL
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
  if (!bmp.begin()) {
    Serial.println("Could not find a valid BMP280 sensor, check wiring!");
    while (1)
      delay(10);
  }
  if (!aht.begin()) {
    Serial.println("Could not find AHT? Check wiring");
    while (1)
      delay(10);
  }

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

    timeClient.begin();
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

  // Endpoint to set state by JSON
  server.on(
    "/set_data", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      // Allocate JsonDocument and parse JSON data
      JsonDocument jsonDoc;
      DeserializationError error = deserializeJson(jsonDoc, (char *)data);

      if (error) {
        request->send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
        return;
      }

      int state = jsonDoc["light1"];
      Serial.println(state);
      if (state == -1) {
        digitalWrite(LED_BUILTIN, LOW);
        Serial.println("Light 1 LOW ");
      } else if (state == 1) {
        digitalWrite(LED_BUILTIN, HIGH);
        Serial.println("Light 1 HIGH ");
      } else if (state == 0) {
        Serial.println("Light 1 is 0 ");
      }

      String jsonToSend;
      serializeJson(jsonDoc, jsonToSend);
      Serial.println(jsonToSend);
      request->send(200, "application/json", jsonToSend);
    });

  // Endpoint to set state by JSON
  server.on(
    "/get_sensor_data", HTTP_POST, [](AsyncWebServerRequest *request) {
      // Allocate JsonDocument and parse JSON data

      JsonDocument jsonDocument;

      sensors_event_t humidity, temp;
      aht.getEvent(&humidity, &temp);  // populate temp and humidity objects with fresh data
      jsonDocument.add(bmp.readTemperature());
      jsonDocument.add(temp.temperature);
      jsonDocument.add(humidity.relative_humidity);
      jsonDocument.add(bmp.readAltitude(101325));
      jsonDocument.add(bmp.readPressure());

      Serial.print("Sensor Data : ");
      String jsonToSend;
      serializeJson(jsonDocument, jsonToSend);

      request->send(200, "application/text", jsonToSend);
    });

  server.begin();
}

void setStateLight1BOS()  // BOS = Based on sensor
{
}

void loop() {
}
