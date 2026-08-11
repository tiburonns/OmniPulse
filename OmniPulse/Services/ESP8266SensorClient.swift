import Foundation
import Observation

@MainActor
@Observable
final class ESP8266SensorClient {
    private(set) var isLoading = false
    private(set) var status = "Conecta el iPhone a la red OmniPulse-8266 de la placa."

    private let endpoint = URL(string: "http://192.168.4.1/scan")!

    func fetchPayload() async throws -> SensorPayload {
        isLoading = true
        status = "Solicitando escaneo al sensor Wi-Fi…"
        defer { isLoading = false }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 25
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            status = "El sensor respondió con un error."
            throw URLError(.badServerResponse)
        }

        let payload = try SensorPayloadDecoder.decode(data)
        status = "Se recibieron \(payload.observations.count) redes de \(payload.sensorName ?? "ESP8266")."
        return payload
    }

    func report(_ error: Error) {
        status = "No se encontró el sensor. Comprueba que estás conectado a OmniPulse-8266 y vuelve a intentar. (\(error.localizedDescription))"
    }
}
