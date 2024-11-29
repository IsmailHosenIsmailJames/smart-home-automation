#include <Arduino.h>
#if defined(ESP32) || defined(ARDUINO_RASPBERRY_PI_PICO_W)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#elif __has_include(<WiFiNINA.h>)
#include <WiFiNINA.h>
#elif __has_include(<WiFi101.h>)
#include <WiFi101.h>
#elif __has_include(<WiFiS3.h>)
#include <WiFiS3.h>
#endif

#include <vector>

#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

#define WIFI_SSID "Ismail"
#define WIFI_PASSWORD "android147890"
#define API_KEY "AIzaSyBJAHkEkobTYYrYkQSvsK9rwM2_VrrbV4E"
#define DATABASE_URL "https://smart-home-automation-724d1-default-rtdb.asia-southeast1.firebasedatabase.app" //<databaseName>.firebaseio.com or <databaseName>.<region>.firebasedatabase.app
#define USER_EMAIL "md.ismailhosenismailjames@gmail.com"
#define USER_PASSWORD "147890"

// Define Firebase Data object
FirebaseData stream;
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

int count = 0;

volatile bool dataChanged = false;

#if defined(ARDUINO_RASPBERRY_PI_PICO_W)
WiFiMulti multi;
#endif

String dataPath;
String valueOnDataPath;

const char *ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 0;
const int daylightOffset_sec = 3600;
struct tm timeInfo;

void streamCallback(FirebaseStream data)
{

  dataPath = "";
  valueOnDataPath = "";

  String dataString = data.stringData();
  if (dataString.indexOf('"') != -1)
  {
    Serial.printf("sream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
                  data.streamPath().c_str(),
                  data.dataPath().c_str(),
                  data.dataType().c_str(),
                  data.eventType().c_str());
    dataString = dataString.substring(2, dataString.length() - 2);
  }
  else
  {
    dataChanged = true;
  }

  Serial.println(dataString);
  Serial.println(data.dataPath());

  size_t len = dataString.length();
  String value = "";
  int i = 0;
  for (i; i < len; i++)
  {
    if (dataString[i] == ':')
    {
      break;
    }
    value += dataString[i];
  }

  Serial.println("pin: ");
  Serial.println(value);

  int pin = value.toInt();

  value = "";
  i++;
  for (i; i < len; i++)
  {
    if (dataString[i] == ':')
    {
      break;
    }
    value += dataString[i];
  }
  Serial.println("State: ");
  Serial.println(value);

  int state = value.toInt();

  // switch state
  digitalWrite(pin, state == 1 ? HIGH : LOW);

  Serial.println(pin);
  Serial.println(state);

  dataPath = data.dataPath();
  valueOnDataPath = dataString;
}

void streamTimeoutCallback(bool timeout)
{
  if (timeout)
    Serial.println("stream timed out, resuming...\n");

  if (!stream.httpConnected())
    Serial.printf("error code: %d, reason: %s\n\n", stream.httpCode(), stream.errorReason().c_str());
}

void setup()
{

  Serial.begin(115200);

#if defined(ARDUINO_RASPBERRY_PI_PICO_W)
  multi.addAP(WIFI_SSID, WIFI_PASSWORD);
  multi.run();
#else
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
#endif

  Serial.print("Connecting to Wi-Fi");
  unsigned long ms = millis();
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
#if defined(ARDUINO_RASPBERRY_PI_PICO_W)
    if (millis() - ms > 10000)
      break;
#endif
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
#if defined(ARDUINO_RASPBERRY_PI_PICO_W)
  config.wifi.clearAP();
  config.wifi.addAP(WIFI_SSID, WIFI_PASSWORD);
#endif

  config.token_status_callback = tokenStatusCallback; // see addons/TokenHelper.h
  Firebase.reconnectNetwork(true);

  // Since v4.4.x, BearSSL engine was used, the SSL buffer need to be set.
  // Large data transmission may require larger RX buffer, otherwise connection issue or data read time out can be occurred.
  fbdo.setBSSLBufferSize(2048 /* Rx buffer size in bytes from 512 - 16384 */, 1024 /* Tx buffer size in bytes from 512 - 16384 */);
  stream.setBSSLBufferSize(2048 /* Rx buffer size in bytes from 512 - 16384 */, 1024 /* Tx buffer size in bytes from 512 - 16384 */);
  Firebase.begin(&config, &auth);

#if defined(ESP32)
  stream.keepAlive(5, 5, 1);
#endif

  if (!Firebase.RTDB.beginStream(&stream, "/app"))
    Serial.printf("sream begin error, %s\n\n", stream.errorReason().c_str());

  Firebase.RTDB.setStreamCallback(&stream, streamCallback, streamTimeoutCallback);
}

void loop()
{

  // Firebase.ready() should be called repeatedly to handle authentication tasks.

#if !defined(ESP8266) && !defined(ESP32)
  Firebase.RTDB.runStream();
#endif

  if (Firebase.ready() && (millis() - sendDataPrevMillis > 10000 || sendDataPrevMillis == 0))
  {
    sendDataPrevMillis = millis();
    if (!getLocalTime(&timeInfo))
    {
      Serial.println("Failed to obtain time");
      return;
    }
    else
    {
      String dateTime = "";
      dateTime += String(timeInfo.tm_year);
      dateTime += "-";
      dateTime += String(timeInfo.tm_mon);
      dateTime += "-";
      dateTime += String(timeInfo.tm_mday);
      dateTime += "-";
      dateTime += String(timeInfo.tm_hour);
      dateTime += "-";
      dateTime += String(timeInfo.tm_min);
      dateTime += "-";
      dateTime += String(timeInfo.tm_sec);

      Serial.printf("Set active... %s\n\n", Firebase.RTDB.setString(&fbdo, "/last_active", dateTime) ? "ok" : fbdo.errorReason().c_str());
    }
  }

  if (dataChanged)
  {
    dataChanged = false;
    String controllerPath = "/controller";
    controllerPath += dataPath;
    Firebase.RTDB.setString(&fbdo, controllerPath, valueOnDataPath);
  }

  // After calling stream.keepAlive, now we can track the server connecting status
  if (!stream.httpConnected())
  {
    // Server was disconnected!
  }
}
