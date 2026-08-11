import Foundation

struct WiFiChannelSample: Hashable, Sendable {
    let identifier: String
    let name: String
    let channel: Int
    let rssi: Int

    var band: WiFiBand { channel <= 14 ? .twoPointFour : .five }
}

enum WiFiBand: String, CaseIterable, Identifiable, Sendable {
    case twoPointFour = "2.4 GHz"
    case five = "5 GHz"

    var id: String { rawValue }
}

struct WiFiChannelStat: Identifiable, Hashable, Sendable {
    let channel: Int
    let band: WiFiBand
    let networkCount: Int
    let strongestRSSI: Int
    let averageRSSI: Double
    let congestionScore: Double

    var id: String { "\(band.rawValue)-\(channel)" }
}

struct WiFiChannelRecommendation: Sendable {
    let band: WiFiBand
    let channel: Int
    let score: Double
    let explanation: String
}

enum WiFiChannelAnalyzer {
    static func samples(from records: [DetectionRecord]) -> [WiFiChannelSample] {
        let wifiRecords = records.filter { $0.transport == "Wi-Fi" && $0.wifiChannel != nil }
        let grouped = Dictionary(grouping: wifiRecords, by: { "\($0.deviceIdentifier)-\($0.wifiChannel!)" })
        return grouped.compactMap { _, entries in
            guard let strongest = entries.max(by: { $0.rssi < $1.rssi }), let channel = strongest.wifiChannel else { return nil }
            return WiFiChannelSample(
                identifier: strongest.deviceIdentifier,
                name: strongest.displayName,
                channel: channel,
                rssi: strongest.rssi
            )
        }
    }

    static func statistics(samples: [WiFiChannelSample]) -> [WiFiChannelStat] {
        Dictionary(grouping: samples, by: { $0.channel })
            .map { channel, entries in
                let average = Double(entries.map(\.rssi).reduce(0, +)) / Double(entries.count)
                return WiFiChannelStat(
                    channel: channel,
                    band: entries[0].band,
                    networkCount: entries.count,
                    strongestRSSI: entries.map(\.rssi).max() ?? -100,
                    averageRSSI: average,
                    congestionScore: entries.reduce(0) { $0 + signalImpact($1.rssi) }
                )
            }
            .sorted { $0.band == $1.band ? $0.channel < $1.channel : $0.band.rawValue < $1.band.rawValue }
    }

    static func recommendation(for band: WiFiBand, samples: [WiFiChannelSample]) -> WiFiChannelRecommendation? {
        let candidates: [Int]
        switch band {
        case .twoPointFour:
            candidates = [1, 6, 11]
        case .five:
            candidates = [36, 40, 44, 48, 149, 153, 157, 161]
        }
        guard !samples.filter({ $0.band == band }).isEmpty else { return nil }

        let scored = candidates.map { candidate in
            (candidate, samples.reduce(0.0) { partial, sample in
                guard sample.band == band else { return partial }
                return partial + signalImpact(sample.rssi) * overlapWeight(candidate: candidate, observed: sample.channel, band: band)
            })
        }
        guard let best = scored.min(by: { $0.1 < $1.1 }) else { return nil }
        let explanation = best.1 < 1
            ? "No se observaron interferencias relevantes en este canal."
            : "Es el canal candidato con menor presión relativa entre las redes observadas."
        return WiFiChannelRecommendation(band: band, channel: best.0, score: best.1, explanation: explanation)
    }

    private static func signalImpact(_ rssi: Int) -> Double {
        Double(max(1, min(70, rssi + 100)))
    }

    private static func overlapWeight(candidate: Int, observed: Int, band: WiFiBand) -> Double {
        let distance = abs(candidate - observed)
        if band == .five { return distance == 0 ? 1 : 0 }
        switch distance {
        case 0: return 1
        case 1: return 0.72
        case 2: return 0.45
        case 3: return 0.22
        case 4: return 0.08
        default: return 0
        }
    }
}
