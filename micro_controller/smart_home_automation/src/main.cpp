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

#include <string>
#include <vector>

#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

#define WIFI_SSID "Ismail"
#define WIFI_PASSWORD "android147890"
#define API_KEY "AIzaSyBJAHkEkobTYYrYkQSvsK9rwM2_VrrbV4E"
#define DATABASE_URL "https://smart-home-automation-724d1-default-rtdb.asia-southeast1.firebasedatabase.app" //<databaseName>.firebaseio.com or <databaseName>.<region>.firebasedatabase.app
#define USER_EMAIL "md.ismailhosenismailjames@gmail.com"
#define USER_PASSWORD "1234567890"

String appPath = "BBzYIYNSDPPBHcvgb4zdurAokhp2/app";
String controllerPath = "BBzYIYNSDPPBHcvgb4zdurAokhp2/controller";
String activityPath = "BBzYIYNSDPPBHcvgb4zdurAokhp2/last_active";

String appStateData = String();
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

const char *ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 0;
const int daylightOffset_sec = 3600;
struct tm timeInfo;

std::vector<std::string> getDataList(std::string data)
{
  int size = data.size();
  int countOfComma = 0;
  for (int i = 0; i < size; i++)
  {
    if (data[i] == ',')
    {
      countOfComma++;
    }
  }

  std::vector<std::string> arrayOfData;
  for (int i = 0; i < countOfComma; i++)
  {
    int size = data.size();
    for (int x = 0; x < size; x++)
    {
      if (data[x] == ',')
      {
        arrayOfData.push_back(data.substr(0, x));
        data = data.substr(x + 1);
        break;
      }
    }
  }
  return arrayOfData;
}

void applyTask(std::string data)
{
  int size = data.size();
  size_t index = data.find(':');
  if (index != -1)
  {
    std::string pin = data.substr(0, index);
    std::string state = data.substr(index + 1, size);
    size_t intPin = std::stoi(pin);
    size_t intSate = std::stoi(state);
    digitalWrite(intPin, intSate == 1 ? HIGH : LOW);
  }
}

void streamCallback(FirebaseStream data)
{
  dataChanged = true;
  String dataString = data.stringData();
  appStateData = dataString;
  std::vector<std::string> arrayOfData = getDataList(dataString.c_str());
  int size = arrayOfData.size();
  for (int i = 0; i < arrayOfData.size(); i++)
  {
    applyTask(arrayOfData[i]);
  }
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
  if (!Firebase.RTDB.beginStream(&stream, appPath))
    Serial.printf("stream begin error, %s\n\n", stream.errorReason().c_str());

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

      Serial.printf("Set active... %s\n\n", Firebase.RTDB.setString(&fbdo, activityPath, dateTime) ? "ok" : fbdo.errorReason().c_str());
    }
  }

  if (dataChanged)
  {
    dataChanged = false;
    Firebase.RTDB.setString(&fbdo, controllerPath, appStateData);
  }

  // After calling stream.keepAlive, now we can track the server connecting status
  if (!stream.httpConnected())
  {
    // Server was disconnected!
  }
}
