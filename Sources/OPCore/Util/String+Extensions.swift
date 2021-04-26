import Foundation

extension String {
    var expandingTildeInPath: String {
        return replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
    }
}
