import Foundation

struct ExistingMobileApp: Codable {

    var _id: Int
    var name: String
    var file: String
    var platform: Platform
    var folderId: Int
    var recipients: [String]?

    init(id: Int, name: String, file: String, platform: Platform, folderId: Int, recipients: [String]? = nil) {
        self._id = id
        self.name = name
        self.file = file
        self.platform = platform
        self.folderId = folderId
        self.recipients = recipients
    }

    private enum CodingKeys: String, CodingKey {
        case _id = "id", name, file, platform, folderId, recipients
    }

}
