import Foundation

struct WiFiChannelSample: Hashable, Sendable {
    let identifier: String
    let name: String
    let channel: Int
    let rssi: Int
    let frequencyMHz: Int?
    let channelWidthMHz: Int?
    let band: WiFiBand

    init(
        identifier: String,
        name: String,
        channel: Int,
        rssi: Int,
        frequencyMHz: Int? = nil,
        channelWidthMHz: Int? = nil,
        band: WiFiBand? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.channel = channel
        self.rssi = rssi
        self.frequencyMHz = frequencyMHz
        self.channelWidthMHz = channelWidthMHz
        self.band = band ?? WiFiBand.infer(
            channel: channel,
            frequencyMHz: frequencyMHz
        )
    }
}

enum WiFiBand: String, CaseIterable, Identifiable, Sendable {
    case twoPointFour = "2.4 GHz"
    case five = "5 GHz"
    case six = "6 GHz"

    var id: String { rawValue }

    static func infer(channel: Int, frequencyMHz: Int?) -> WiFiBand {
        if let frequencyMHz {
            if (2_400..<2_500).contains(frequencyMHz) {
                return .twoPointFour
            }
            if (5_925...7_125).contains(frequencyMHz) {
                return .six
            }
            if (4_900..<5_925).contains(frequencyMHz) {
                return .five
            }
        }

        // Channel numbers overlap between 2.4/5/6 GHz. Without a measured
        // frequency, keep the legacy conservative inference instead of
        // pretending a low 6 GHz channel can be identified reliably.
        return channel <= 14 ? .twoPointFour : .five
    }
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
    let channelWidthMHz: Int
    let score: Double
    let observedNetworkCount: Int
    let isPotentialDFS: Bool
    let explanation: String
}

enum WiFiChannelAnalyzer {
    private static let allowedWidths = [20, 40, 80, 160, 320]
    private static let twoPointFourCandidates = [1, 6, 11]
    private static let fiveNonDFSCandidates = [36, 40, 44, 48, 149, 153, 157, 161]
    private static let fivePotentialDFSCandidates = [
        52, 56, 60, 64,
        100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144
    ]
    // 6 GHz Preferred Scanning Channels (PSC). Availability still depends on
    // the country, access-point mode and client hardware.
    private static let sixGHzPSCCandidates = [
        5, 21, 37, 53, 69, 85, 101, 117,
        133, 149, 165, 181, 197, 213, 229
    ]

    static func samples(from records: [DetectionRecord]) -> [WiFiChannelSample] {
        let wifiSamples = records.compactMap { record -> WiFiChannelSample? in
            guard record.transport == "Wi-Fi",
                  let channel = record.wifiChannel else {
                return nil
            }

            return WiFiChannelSample(
                identifier: record.deviceIdentifier,
                name: record.displayName,
                channel: channel,
                rssi: record.rssi,
                frequencyMHz: record.wifiFrequencyMHz,
                channelWidthMHz: record.wifiChannelWidthMHz
            )
        }

        let grouped = Dictionary(grouping: wifiSamples) {
            "\($0.identifier)-\($0.band.rawValue)-\($0.channel)"
        }

        return grouped.compactMap { _, entries in
            entries.max(by: { $0.rssi < $1.rssi })
        }
    }

    static func statistics(samples: [WiFiChannelSample]) -> [WiFiChannelStat] {
        Dictionary(grouping: samples) {
            "\($0.band.rawValue)-\($0.channel)"
        }
        .compactMap { _, entries in
            guard let first = entries.first else { return nil }
            let average = Double(entries.map(\.rssi).reduce(0, +))
                / Double(entries.count)

            return WiFiChannelStat(
                channel: first.channel,
                band: first.band,
                networkCount: entries.count,
                strongestRSSI: entries.map(\.rssi).max() ?? -100,
                averageRSSI: average,
                congestionScore: entries.reduce(0) {
                    $0 + signalImpact($1.rssi)
                }
            )
        }
        .sorted {
            if $0.band == $1.band {
                return $0.channel < $1.channel
            }
            return bandOrder($0.band) < bandOrder($1.band)
        }
    }

    static func recommendation(
        for band: WiFiBand,
        samples: [WiFiChannelSample],
        channelWidthMHz: Int = 20,
        includePotentialDFS: Bool = false
    ) -> WiFiChannelRecommendation? {
        let bandSamples = samples.filter { $0.band == band }
        guard !bandSamples.isEmpty else { return nil }

        let width = normalizedWidth(channelWidthMHz, for: band)
        let candidates = candidateChannels(
            for: band,
            includePotentialDFS: includePotentialDFS
        )
        guard !candidates.isEmpty else { return nil }

        let scored = candidates.map { candidate -> (Int, Double) in
            let score = bandSamples.reduce(0.0) { partial, sample in
                partial
                    + signalImpact(sample.rssi)
                    * overlapWeight(
                        candidate: candidate,
                        candidateWidthMHz: width,
                        observed: sample
                    )
            }
            return (candidate, score)
        }

        guard let best = scored.min(by: {
            if $0.1 == $1.1 { return $0.0 < $1.0 }
            return $0.1 < $1.1
        }) else {
            return nil
        }

        let dfs = band == .five && isPotentialDFS(best.0)
        let explanation: String
        if best.1 < 0.01 {
            explanation = "No se observó presión espectral relevante sobre este canal."
        } else if dfs {
            explanation = "Es el candidato con menor presión observada, pero puede requerir DFS según la región y el punto de acceso."
        } else {
            explanation = "Es el candidato con menor presión espectral relativa entre las redes observadas."
        }

        return WiFiChannelRecommendation(
            band: band,
            channel: best.0,
            channelWidthMHz: width,
            score: best.1,
            observedNetworkCount: bandSamples.count,
            isPotentialDFS: dfs,
            explanation: explanation
        )
    }

    static func centerFrequencyMHz(
        channel: Int,
        band: WiFiBand
    ) -> Double? {
        switch band {
        case .twoPointFour:
            if channel == 14 { return 2_484 }
            guard (1...13).contains(channel) else { return nil }
            return Double(2_407 + (channel * 5))
        case .five:
            guard (1...196).contains(channel) else { return nil }
            return Double(5_000 + (channel * 5))
        case .six:
            guard (1...233).contains(channel) else { return nil }
            return Double(5_950 + (channel * 5))
        }
    }

    static func isPotentialDFS(_ channel: Int) -> Bool {
        fivePotentialDFSCandidates.contains(channel)
    }

    private static func candidateChannels(
        for band: WiFiBand,
        includePotentialDFS: Bool
    ) -> [Int] {
        switch band {
        case .twoPointFour:
            return twoPointFourCandidates
        case .five:
            return includePotentialDFS
                ? (fiveNonDFSCandidates + fivePotentialDFSCandidates).sorted()
                : fiveNonDFSCandidates
        case .six:
            return sixGHzPSCCandidates
        }
    }

    private static func normalizedWidth(
        _ requested: Int,
        for band: WiFiBand
    ) -> Int {
        let supported = allowedWidths.filter {
            if band == .twoPointFour { return $0 <= 40 }
            if band == .five { return $0 <= 160 }
            return true
        }
        return supported.min(by: {
            abs($0 - requested) < abs($1 - requested)
        }) ?? 20
    }

    private static func signalImpact(_ rssi: Int) -> Double {
        let clamped = max(-100, min(-30, rssi))
        return pow(10, Double(clamped + 100) / 20.0)
    }

    private static func overlapWeight(
        candidate: Int,
        candidateWidthMHz: Int,
        observed sample: WiFiChannelSample
    ) -> Double {
        guard let candidateCenter = centerFrequencyMHz(
            channel: candidate,
            band: sample.band
        ) else {
            return 0
        }

        let observedCenter = sample.frequencyMHz.map(Double.init)
            ?? centerFrequencyMHz(
                channel: sample.channel,
                band: sample.band
            )

        guard let observedCenter else { return 0 }

        let observedWidth = normalizedWidth(
            sample.channelWidthMHz ?? 20,
            for: sample.band
        )
        let reach = (
            Double(candidateWidthMHz)
                + Double(observedWidth)
        ) / 2.0
        guard reach > 0 else { return 0 }

        let distance = abs(candidateCenter - observedCenter)
        guard distance < reach else { return 0 }

        return max(0.02, 1.0 - (distance / reach))
    }

    private static func bandOrder(_ band: WiFiBand) -> Int {
        switch band {
        case .twoPointFour: return 0
        case .five: return 1
        case .six: return 2
        }
    }
}
