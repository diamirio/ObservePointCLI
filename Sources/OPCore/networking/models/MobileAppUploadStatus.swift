import Foundation

struct MobileAppUploadStatus: Codable {
    var uploadId: UUID
    var app: StoreApp?
}
