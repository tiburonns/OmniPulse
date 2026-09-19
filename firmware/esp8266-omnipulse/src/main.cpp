#include <Arduino.h>
#include <ArduinoJson.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>

namespace {

constexpr char kFirmwareVersion[] = "1.1.0";
constexpr int kMaximumWiFiResults = 20;

#ifndef OMNIPULSE_BOARD_PROFILE
#define OMNIPULSE_BOARD_PROFILE "ESP8266"
#endif

ESP8266WebServer server(80);
String sensorID;
String sensorName;
String accessPointName;
String accessPointPassword;
String sessionSalt;

String pseudonym(const String& input) {
    uint32_t hash = 2166136261UL;
    const String material = sessionSalt + ":" + input;
    for (size_t index = 0; index < material.length(); index++) {
        hash ^= static_cast<uint8_t>(material[index]);
        hash *= 16777619UL;
    }
    char suffix[9];
    snprintf(suffix, sizeof(suffix), "%08lx", static_cast<unsigned long>(hash));
    return "wifi-" + String(suffix);
}

void sendStatus() {
    JsonDocument document;
    document["name"] = sensorName;
    document["hardware"] = OMNIPULSE_BOARD_PROFILE;
    document["firmwareVersion"] = kFirmwareVersion;
    document["network"] = accessPointName;
    String payload;
    serializeJson(document, payload);
    server.send(200, "application/json", payload);
}

int wifiFrequencyMHz(int channel) {
    if (channel == 14) {
        return 2484;
    }
    if (channel >= 1 && channel <= 13) {
        return 2407 + (channel * 5);
    }
    return -1;
}

void sendScan() {
    const int networkCount = WiFi.scanNetworks(false, true);
    if (networkCount < 0) {
        server.send(503, "application/json", "{\"error\":\"scan_failed\"}");
        return;
    }

    JsonDocument document;
    document["version"] = 1;
    document["sensorID"] = sensorID;
    document["sensorName"] = sensorName;
    document["firmwareVersion"] = kFirmwareVersion;
    document["hardware"] = OMNIPULSE_BOARD_PROFILE;
    JsonArray observations = document["observations"].to<JsonArray>();
    const int resultCount = min(networkCount, kMaximumWiFiResults);
    for (int index = 0; index < resultCount; index++) {
        JsonObject observation = observations.add<JsonObject>();
        const String ssid = WiFi.SSID(index);
        const String fingerprint = ssid + ":" + String(WiFi.channel(index));
        observation["kind"] = "wifiNetwork";
        observation["identifier"] = pseudonym(fingerprint);
        observation["name"] = ssid.isEmpty() ? "Red oculta" : ssid;
        observation["rssi"] = WiFi.RSSI(index);
        const int channel = WiFi.channel(index);
        observation["channel"] = channel;
        const int frequencyMHz = wifiFrequencyMHz(channel);
        if (frequencyMHz > 0) {
            observation["frequencyMHz"] = frequencyMHz;
        }
    }

    String payload;
    serializeJson(document, payload);
    WiFi.scanDelete();
    server.send(200, "application/json", payload);
}

}  // namespace

void setup() {
    Serial.begin(115200);
    delay(50);

    const uint32_t chipID = ESP.getChipId();
    sessionSalt = String(chipID, HEX) + String(micros(), HEX);
    sensorID = "omnipulse-8266-" + String(chipID, HEX);
    String accessPointSuffix = String(chipID & 0xFFFF, HEX);
    accessPointSuffix.toUpperCase();
    while (accessPointSuffix.length() < 4) {
        accessPointSuffix = "0" + accessPointSuffix;
    }
    accessPointName = "OmniPulse-8266-" + accessPointSuffix;
    accessPointPassword = "omni" + accessPointSuffix;
    sensorName = "OmniPulse " + accessPointName.substring(accessPointName.length() - 4);

    WiFi.persistent(false);
    WiFi.mode(WIFI_AP_STA);
    WiFi.softAP(accessPointName.c_str(), accessPointPassword.c_str());

    server.on("/", HTTP_GET, sendStatus);
    server.on("/status", HTTP_GET, sendStatus);
    server.on("/scan", HTTP_GET, sendScan);
    server.begin();

    Serial.printf("%s ready at http://192.168.4.1 (password: %s)\n", accessPointName.c_str(), accessPointPassword.c_str());
}

void loop() {
    server.handleClient();
    delay(2);
}
