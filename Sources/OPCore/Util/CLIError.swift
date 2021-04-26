import Foundation

enum CLIError: LocalizedError {
    case retrievingAppInfoFailed(id: Int, Error)
    case retrievingFoldersFailed(Error)
    case retrievingAppJourneysForAppFailed(appId: Int, Error)
    case observePointFolderMissing(String)
    case createAppFailed(Error)
    case uploadAppFileFailed(Error)
    case wrongUploadState(expected: StoreApp.UploadState, actual: StoreApp.UploadState?)
    case checkingUploadStateFailed(Error)
    case triggeringAllAppJourneysFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .retrievingAppInfoFailed(id, error):
            return "Retrieving app with id \(id) failed. (Underlying error: \(error)"
            
        case let .retrievingAppJourneysForAppFailed(id, error):
            return "Retrieving app journeys for app with id \(id) failed. (Underlying error: \(error)"
            
        case let .triggeringAllAppJourneysFailed(error):
            return "Triggering a run for all app journeys failed. (Underlying error: \(error)"
            
        case .retrievingFoldersFailed(let error):
            return "Retrieving folders failed. (Underlying error: \(error))"

        case let .observePointFolderMissing(name):
            return "Folder with name '\(name)' not found."
            
        case let .createAppFailed(error):
            return "Creating app failed. (Underlying error: \(error))"
            
        case let .uploadAppFileFailed(error):
            return "Uploading app file failed. (Underlying error: \(error))"
            
        case let .wrongUploadState(expected, actual):
            return "Expected upload state \(expected), but found state \(String(describing: actual))."
            
        case let .checkingUploadStateFailed(error):
            return "Checking upload state failed. (Underlying error: \(error))"

        }
    }
}
