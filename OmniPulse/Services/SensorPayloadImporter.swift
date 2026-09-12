import CoreLocation
import Foundation
import SwiftData

struct SensorPayloadImporter {
    @MainActor
    func importBatch(
        _ batch: ReceivedSensorBatch,
        location: CLLocation?,
        projectID: UUID? = SurveyProjectSelection.activeProjectID,
        into modelContext: ModelContext
    ) throws -> Int {
        for observation in batch.payload.observations {
            let source = source(for: observation.kind)
            let defaultName = observation.kind == .wifiNetwork ? "Red oculta" : "Dispositivo BLE"
            let record = DetectionRecord(
                deviceIdentifier: observation.identifier,
                deviceName: observation.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? observation.name!
                    : defaultName,
                transport: source.transportLabel,
                source: source.rawValue,
                rssi: observation.rssi,
                wifiChannel: observation.channel,
                seenAt: observation.seenAt ?? batch.receivedAt,
                location: location,
                projectID: projectID,
                manufacturerName: observation.manufacturerID.map { String(format: "Fabricante 0x%04X", $0) },
                beaconType: observation.beaconType,
                sensorIdentifier: batch.payload.sensorID,
                sensorHardware: batch.payload.hardware,
                sensorFirmwareVersion: batch.payload.firmwareVersion
            )
            modelContext.insert(record)
        }
        try modelContext.save()
        _ = try DetectionHistoryRetention.pruneUsingSavedPolicy(in: modelContext)
        return batch.observationCount
    }

    private func source(for kind: SensorObservationKind) -> DetectionSource {
        switch kind {
        case .wifiNetwork:
            .esp32WiFi
        case .bluetoothLE:
            .esp32BLE
        }
    }
}
