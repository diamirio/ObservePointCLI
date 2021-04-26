import Foundation

public struct StoreApp: Codable {

    public enum UploadState: String, Codable { 
        case notUploaded = "notUploaded"
        case updating = "updating"
        case finished = "finished"
    }
    
    public var _id: Int
    public var name: String
    public var folderId: Int
    public var uploadState: UploadState?

    public init(_id: Int, name: String, folderId: Int, uploadState: UploadState? = nil) {
        self._id = _id
        self.name = name
        self.folderId = folderId
        self.uploadState = uploadState
    }

    public enum CodingKeys: String, CodingKey { 
        case _id = "id"
        case name
        case folderId
        case uploadState
    }

}
