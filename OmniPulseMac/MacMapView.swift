import MapKit
import SwiftData
import SwiftUI

struct MacMapView: View {
    @Environment(AppTheme.self) private var appTheme
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var records: [DetectionRecord]
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if locatedRecords.isEmpty {
                ContentUnavailableView("Sin registros con ubicación", systemImage: "map")
            } else {
                Map(position: $position) {
                    ForEach(locatedRecords) { record in
                        if let coordinate = record.coordinate {
                            Marker(record.displayName, coordinate: coordinate)
                                .tint(record.transport == "Wi-Fi" ? appTheme.warning : appTheme.accent)
                        }
                    }
                }
                .onAppear(perform: center)
            }
        }
        .navigationTitle("Mapa")
        .toolbar { Button("Centrar", systemImage: "scope", action: center) }
    }

    private var locatedRecords: [DetectionRecord] { records.filter(\.hasLocation) }

    private func center() {
        guard let coordinate = locatedRecords.first?.coordinate else { return }
        position = .region(MKCoordinateRegion(center: coordinate, span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)))
    }
}
