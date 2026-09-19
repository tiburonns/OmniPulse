#include <Arduino.h>
#include <ArduinoJson.h>
#include <NimBLEDevice.h>
#include <Update.h>
#include <WiFi.h>
#include <esp_system.h>
#include <esp_ota_ops.h>
#include <mbedtls/sha256.h>

namespace {

constexpr char kServiceUUID[] = "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A101";
constexpr char kObservationsCharacteristicUUID[] = "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A102";
constexpr char kFirmwareControlCharacteristicUUID[] = "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A103";
constexpr char kFirmwareDataCharacteristicUUID[] = "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A104";
constexpr char kFirmwareVersion[] = "1.4.0";
constexpr uint32_t kCaptureIntervalMs = 15000;
constexpr uint32_t kBLEScanDurationMs = 3000;
constexpr int kMaximumWiFiResults = 8;
constexpr int kMaximumBLEResults = 8;

NimBLECharacteristic* observationsCharacteristic = nullptr;
NimBLECharacteristic* firmwareControlCharacteristic = nullptr;
NimBLECharacteristic* firmwareDataCharacteristic = nullptr;
NimBLEScan* nearbyBLEScanner = nullptr;
NimBLEServer* sensorServer = nullptr;
NimBLEAdvertising* sensorAdvertising = nullptr;
String sensorID;
String sensorName;
String sessionSalt;
uint32_t lastCaptureAt = 0;
uint32_t lastAdvertisingCheckAt = 0;
uint32_t restartAt = 0;
bool otaInProgress = false;
size_t otaExpectedSize = 0;
size_t otaReceivedSize = 0;
String otaExpectedSHA256;
mbedtls_sha256_context otaSHA256;
bool otaSHA256Initialized = false;
bool pendingFirmwareValidation = false;
uint32_t firmwareValidationStartedAt = 0;

#ifndef OMNIPULSE_BOARD_PROFILE
#define OMNIPULSE_BOARD_PROFILE "ESP32"
#endif

// Lab OTA is off in every distributed build. Enabling it requires an explicit
// local build flag and an authenticated, encrypted BLE link. Firmware signing
// and signed images are still required before enabling OTA in production.
#ifndef OMNIPULSE_ENABLE_LAB_OTA
#define OMNIPULSE_ENABLE_LAB_OTA 0
#endif

class SensorServerCallbacks : public NimBLEServerCallbacks {
    void onDisconnect(NimBLEServer* server, NimBLEConnInfo& connection, int reason) override {
        Serial.printf("iPhone disconnected (reason %d); restarting advertising\n", reason);
        NimBLEDevice::startAdvertising();
    }
} sensorServerCallbacks;

void publishFirmwareStatus(const char* state, const String& message = "") {
    if (firmwareControlCharacteristic == nullptr) {
        return;
    }
    JsonDocument document;
    document["state"] = state;
    document["uptimeSeconds"] = millis() / 1000;
    document["freeHeapBytes"] = ESP.getFreeHeap();
    document["rollbackProtection"] = true;
    if (!message.isEmpty()) {
        document["message"] = message;
    }
    String payload;
    serializeJson(document, payload);
    firmwareControlCharacteristic->setValue(payload.c_str());
    firmwareControlCharacteristic->notify();
}

String sha256Hex(const unsigned char digest[32]) {
    char output[65];
    for (size_t index = 0; index < 32; index++) {
        snprintf(output + index * 2, 3, "%02x", digest[index]);
    }
    output[64] = '\0';
    return String(output);
}

void startSHA256(mbedtls_sha256_context* context) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
    mbedtls_sha256_starts(context, 0);
#else
    mbedtls_sha256_starts_ret(context, 0);
#endif
}

void updateSHA256(mbedtls_sha256_context* context, const unsigned char* data, size_t size) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
    mbedtls_sha256_update(context, data, size);
#else
    mbedtls_sha256_update_ret(context, data, size);
#endif
}

void finishSHA256(mbedtls_sha256_context* context, unsigned char digest[32]) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
    mbedtls_sha256_finish(context, digest);
#else
    mbedtls_sha256_finish_ret(context, digest);
#endif
}

void failFirmwareUpdate(const String& message) {
    Update.abort();
    otaInProgress = false;
    otaExpectedSize = 0;
    otaReceivedSize = 0;
    if (otaSHA256Initialized) {
        mbedtls_sha256_free(&otaSHA256);
        otaSHA256Initialized = false;
    }
    publishFirmwareStatus("error", message);
    Serial.printf("OTA failed: %s\n", message.c_str());
}

class FirmwareControlCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo& connection) override {
        const auto value = characteristic->getValue();
        JsonDocument document;
        if (deserializeJson(document, value.data(), value.size())) {
            publishFirmwareStatus("error", "Comando OTA no válido");
            return;
        }

        const String command = document["cmd"] | "";
        if (command == "begin") {
            if (otaInProgress) {
                failFirmwareUpdate("Ya existe una actualización activa");
            }
            otaExpectedSize = document["size"] | 0;
            otaExpectedSHA256 = String(document["sha256"] | "");
            otaReceivedSize = 0;
            if (otaExpectedSize == 0 || otaExpectedSHA256.length() != 64 || !Update.begin(otaExpectedSize)) {
                failFirmwareUpdate("No hay espacio para el firmware");
                return;
            }
            mbedtls_sha256_init(&otaSHA256);
            startSHA256(&otaSHA256);
            otaSHA256Initialized = true;
            otaInProgress = true;
            publishFirmwareStatus("ready");
            Serial.printf("OTA ready for %u bytes\n", static_cast<unsigned int>(otaExpectedSize));
        } else if (command == "finish") {
            if (!otaInProgress || otaReceivedSize != otaExpectedSize) {
                failFirmwareUpdate("La transferencia quedó incompleta");
                return;
            }
            unsigned char digest[32];
            finishSHA256(&otaSHA256, digest);
            mbedtls_sha256_free(&otaSHA256);
            otaSHA256Initialized = false;
            const String actualSHA256 = sha256Hex(digest);
            if (!actualSHA256.equalsIgnoreCase(otaExpectedSHA256)) {
                failFirmwareUpdate("La verificación SHA-256 no coincide");
                return;
            }
            if (!Update.end(true)) {
                failFirmwareUpdate("No se pudo finalizar la instalación");
                return;
            }
            otaInProgress = false;
            publishFirmwareStatus("complete");
            restartAt = millis() + 1500;
            Serial.println("OTA complete; restarting");
        }
    }
} firmwareControlCallbacks;

class FirmwareDataCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo& connection) override {
        if (!otaInProgress) {
            return;
        }
        const auto value = characteristic->getValue();
        if (value.size() == 0 || otaReceivedSize + value.size() > otaExpectedSize) {
            failFirmwareUpdate("Se recibió un bloque OTA fuera de rango");
            return;
        }
        const size_t written = Update.write(const_cast<uint8_t*>(value.data()), value.size());
        if (written != value.size()) {
            failFirmwareUpdate("No se pudo escribir el bloque OTA");
            return;
        }
        updateSHA256(&otaSHA256, value.data(), value.size());
        otaReceivedSize += written;
    }
} firmwareDataCallbacks;

String pseudonym(const String& input, const char* prefix) {
    // An ephemeral FNV-1a-based pseudonym. It prevents raw radio identifiers
    // from leaving the sensor and resets whenever the sensor restarts.
    uint32_t hash = 2166136261UL;
    const String material = sessionSalt + ":" + input;
    for (size_t index = 0; index < material.length(); index++) {
        hash ^= static_cast<uint8_t>(material[index]);
        hash *= 16777619UL;
    }

    char suffix[9];
    snprintf(suffix, sizeof(suffix), "%08lx", static_cast<unsigned long>(hash));
    return String(prefix) + suffix;
}

int wifiFrequencyMHz(int channel) {
    if (channel == 14) {
        return 2484;
    }
    if (channel >= 1 && channel <= 13) {
        return 2407 + (channel * 5);
    }
    // ESP32-C5 can report 5 GHz channels. Preserve a center-frequency hint
    // so the app does not have to infer the band from channel numbering alone.
    if (channel >= 32 && channel <= 196) {
        return 5000 + (channel * 5);
    }
    return -1;
}

void publishObservation(
    const char* kind,
    const String& identifier,
    int rssi,
    const String& name = "",
    int channel = -1
) {
    if (observationsCharacteristic == nullptr) {
        return;
    }

    // One observation per GATT notification keeps payloads below the default
    // ATT MTU in most iPhone connections. The iPhone timestamps receipt.
    JsonDocument document;
    document["version"] = 1;
    document["sensorID"] = sensorID;
    document["sensorName"] = sensorName;
    document["firmwareVersion"] = kFirmwareVersion;
    document["hardware"] = OMNIPULSE_BOARD_PROFILE;
    document["uptimeSeconds"] = millis() / 1000;
    document["freeHeapBytes"] = ESP.getFreeHeap();
    JsonArray observations = document["observations"].to<JsonArray>();
    JsonObject observation = observations.add<JsonObject>();
    observation["kind"] = kind;
    observation["identifier"] = identifier;
    observation["rssi"] = rssi;
    if (!name.isEmpty()) {
        observation["name"] = name;
    }
    if (channel > 0) {
        observation["channel"] = channel;
        const int frequencyMHz = wifiFrequencyMHz(channel);
        if (frequencyMHz > 0) {
            observation["frequencyMHz"] = frequencyMHz;
        }
    }

    String payload;
    serializeJson(document, payload);
    observationsCharacteristic->setValue(payload.c_str());
    observationsCharacteristic->notify();
    Serial.printf("Published %s: %s\n", kind, payload.c_str());
}

void scanWiFiNetworks() {
    const int networkCount = WiFi.scanNetworks(/* async */ false, /* show hidden */ true);
    if (networkCount < 0) {
        Serial.println("Wi-Fi scan failed");
        return;
    }

    const int resultCount = min(networkCount, kMaximumWiFiResults);
    for (int index = 0; index < resultCount; index++) {
        // An SSID plus channel is enough to deduplicate visible networks for
        // this short session. BSSID/MAC is never placed in the payload.
        const String fingerprint = WiFi.SSID(index) + ":" + String(WiFi.channel(index));
        const String networkName = WiFi.SSID(index).isEmpty() ? "Red oculta" : WiFi.SSID(index);
        publishObservation(
            "wifiNetwork",
            pseudonym(fingerprint, "wifi-"),
            WiFi.RSSI(index),
            networkName,
            WiFi.channel(index)
        );
    }

    WiFi.scanDelete();
}

void scanBLEAdvertisements() {
    const NimBLEScanResults results = nearbyBLEScanner->getResults(kBLEScanDurationMs);
    const int resultCount = min(results.getCount(), kMaximumBLEResults);

    for (int index = 0; index < resultCount; index++) {
        const NimBLEAdvertisedDevice* device = results.getDevice(index);
        if (device == nullptr) {
            continue;
        }
        // The address is used only inside the sensor to make a session-local
        // pseudonym. It is never serialised or logged outside this device.
        const String advertisedName = device->haveName()
            ? String(device->getName().c_str())
            : String("Dispositivo BLE");
        publishObservation(
            "bluetoothLE",
            pseudonym(String(device->getAddress().toString().c_str()), "ble-"),
            device->getRSSI(),
            advertisedName
        );
    }

    nearbyBLEScanner->clearResults();
}

void captureNearbyRadioObservations() {
    Serial.println("Starting authorized radio observation cycle");
    scanWiFiNetworks();
    scanBLEAdvertisements();
}

void startBLEService() {
    NimBLEDevice::init(sensorName.c_str());
#if OMNIPULSE_ENABLE_LAB_OTA
    NimBLEDevice::setSecurityAuth(/* bonding */ true, /* mitm */ true, /* secure connections */ true);
#endif

    sensorServer = NimBLEDevice::createServer();
    sensorServer->setCallbacks(&sensorServerCallbacks);
    NimBLEService* service = sensorServer->createService(kServiceUUID);
    observationsCharacteristic = service->createCharacteristic(
        kObservationsCharacteristicUUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );
    observationsCharacteristic->setValue("{\"version\":1,\"sensorID\":\"pending\",\"observations\":[]}");
#if OMNIPULSE_ENABLE_LAB_OTA
    firmwareControlCharacteristic = service->createCharacteristic(
        kFirmwareControlCharacteristicUUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_ENC |
            NIMBLE_PROPERTY::WRITE_AUTHEN | NIMBLE_PROPERTY::NOTIFY
    );
    firmwareDataCharacteristic = service->createCharacteristic(
        kFirmwareDataCharacteristicUUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR |
            NIMBLE_PROPERTY::WRITE_ENC | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    firmwareControlCharacteristic->setCallbacks(&firmwareControlCallbacks);
    firmwareDataCharacteristic->setCallbacks(&firmwareDataCallbacks);
#else
    Serial.println("BLE OTA disabled: build with explicit lab-only authorization to expose it");
#endif
    sensorAdvertising = NimBLEDevice::getAdvertising();
    sensorAdvertising->addServiceUUID(kServiceUUID);
    sensorAdvertising->enableScanResponse(true);
    sensorAdvertising->start();

    nearbyBLEScanner = NimBLEDevice::getScan();
    nearbyBLEScanner->setActiveScan(true);
    nearbyBLEScanner->setInterval(100);
    nearbyBLEScanner->setWindow(99);
}

void beginFirmwareValidationIfNeeded() {
    const esp_partition_t* runningPartition = esp_ota_get_running_partition();
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(runningPartition, &state) == ESP_OK && state == ESP_OTA_IMG_PENDING_VERIFY) {
        pendingFirmwareValidation = true;
        firmwareValidationStartedAt = millis();
        Serial.println("New OTA image pending health validation");
    }
}

void validatePendingFirmware() {
    if (!pendingFirmwareValidation) {
        return;
    }
    const uint32_t elapsed = millis() - firmwareValidationStartedAt;
    const bool servicesHealthy = sensorServer != nullptr && sensorAdvertising != nullptr && nearbyBLEScanner != nullptr;
    const bool memoryHealthy = ESP.getFreeHeap() >= 30000;
    if (elapsed >= 30000 && servicesHealthy && memoryHealthy) {
        if (esp_ota_mark_app_valid_cancel_rollback() == ESP_OK) {
            pendingFirmwareValidation = false;
            Serial.println("OTA image validated; automatic rollback cancelled");
        }
    } else if (elapsed >= 120000) {
        Serial.println("OTA image failed health validation; rolling back");
        esp_ota_mark_app_invalid_rollback_and_reboot();
    }
}

}  // namespace

void setup() {
    Serial.begin(115200);
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(false, false);

    sessionSalt = String(static_cast<uint32_t>(esp_random()), HEX);
    sensorID = "omnipulse-" + String(static_cast<uint32_t>(ESP.getEfuseMac() & 0xFFFF), HEX);
    sensorName = "OmniPulse " + sensorID.substring(sensorID.length() - 4);
    startBLEService();
    beginFirmwareValidationIfNeeded();

    Serial.printf("%s ready: %s (firmware %s)\n", sensorName.c_str(), sensorID.c_str(), kFirmwareVersion);
}

void loop() {
    validatePendingFirmware();
    if (restartAt > 0 && static_cast<int32_t>(millis() - restartAt) >= 0) {
        ESP.restart();
    }
    if (millis() - lastAdvertisingCheckAt >= 5000) {
        lastAdvertisingCheckAt = millis();
        if (sensorServer != nullptr && sensorAdvertising != nullptr &&
            sensorServer->getConnectedCount() == 0 && !sensorAdvertising->isAdvertising()) {
            Serial.println("Advertising watchdog restarted BLE advertising");
            sensorAdvertising->start();
        }
    }

    if (!otaInProgress && millis() - lastCaptureAt >= kCaptureIntervalMs) {
        lastCaptureAt = millis();
        captureNearbyRadioObservations();
    }
    delay(50);
}
