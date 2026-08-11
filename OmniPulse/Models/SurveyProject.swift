import Foundation
import SwiftData

@Model
final class SurveyProject {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    @Attribute(.externalStorage) var floorPlanData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        floorPlanData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.floorPlanData = floorPlanData
    }
}

enum SurveyProjectSelection {
    private static let activeProjectKey = "activeSurveyProjectID"

    static var activeProjectID: UUID? {
        get {
            guard let value = UserDefaults.standard.string(forKey: activeProjectKey) else { return nil }
            return UUID(uuidString: value)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: activeProjectKey)
        }
    }
}
