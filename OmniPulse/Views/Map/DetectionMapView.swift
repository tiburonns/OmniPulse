import CoreLocation
import MapKit
import SwiftData
import SwiftUI

private struct MapDetection: Identifiable {
    let record: DetectionRecord
    let coordinate: CLLocationCoordinate2D

    var id: UUID { record.id }
}

struct DetectionMapView: View {
    @Environment(AppTheme.self) private var appTheme
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var records: [DetectionRecord]
    @State private var position: MapCameraPosition = .automatic

    private var mapDetections: [MapDetection] {
        records.compactMap { record in
            guard let coordinate = record.coordinate else { return nil }
            return MapDetection(record: record, coordinate: coordinate)
        }
    }

    var body: some View {
        Group {
            if mapDetections.isEmpty {
                ContentUnavailableView(
                    "Sin registros con ubicación",
                    systemImage: "map",
                    description: Text("Actualiza la ubicación antes de guardar una detección para verla aquí.")
                )
            } else {
                Map(position: $position) {
                    ForEach(mapDetections) { detection in
                        Marker(detection.record.displayName, coordinate: detection.coordinate)
                            .tint(markerColor(for: detection.record))
                    }
                }
                .mapStyle(.standard)
                .onAppear(perform: centerOnLatestRecord)
                .onChange(of: mapDetections.count) { _, _ in
                    centerOnLatestRecord()
                }
            }
        }
        .navigationTitle("Mapa")
        .toolbar {
            if !mapDetections.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Centrar", systemImage: "scope") {
                        centerOnLatestRecord()
                    }
                }
            }
        }
    }

    private func markerColor(for record: DetectionRecord) -> Color {
        switch record.transport {
        case "Wi-Fi":
            appTheme.warning
        case "ESP32 BLE":
            appTheme.success
        default:
            appTheme.accent
        }
    }

    private func centerOnLatestRecord() {
        guard let first = mapDetections.first else { return }
        position = .region(
            MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}
