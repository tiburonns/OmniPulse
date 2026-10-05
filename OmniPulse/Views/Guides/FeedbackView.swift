import SwiftUI

struct FeedbackView: View {
    @State private var category = "Sugerencia"
    @State private var message = ""
    @Environment(\.openURL) private var openURL

    private let categories = ["Duda", "Sugerencia", "Error", "Feedback", "Compatibilidad", "Otro"]

    var body: some View {
        Form {
            Section("Tipo") {
                Picker("Categoría", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
            }

            Section("Comentario") {
                TextEditor(text: $message)
                    .frame(minHeight: 160)
                Text("No incluyas contraseñas, direcciones MAC ni información personal sensible.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    sendFeedback()
                } label: {
                    Label("Enviar comentario", systemImage: "paperplane.fill")
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("Se abrirá GitHub para que revises y publiques el comentario.")
            }
        }
        .navigationTitle("Soporte y feedback")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendFeedback() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = "/tiburonns/OmniPulse/issues/new"
        components.queryItems = [
            URLQueryItem(name: "template", value: "feedback.yml"),
            URLQueryItem(name: "title", value: "[\(category)] "),
            URLQueryItem(name: "message", value: message)
        ]
        if let url = components.url {
            openURL(url)
        }
    }
}
