import Foundation
import ArgumentParser
import Combine
import Endpoints

private var service: UpdateAppService!

public struct UpdateAppCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "update-app",
        abstract: """
            A(n) (unofficial) utility for interacting with the ObservePoint API.
            * Fetches information about the app
            * Uploads the passed `<file>`
            * Triggers all journeys that are linked to the app.
            """
    )
    
    public static var onCompletion: ((_ success: Bool) -> Void)? = nil
    
    @Option(help: "The api key for the ObservePoint API")
    public var apiKey: String
    
    @Option
    public var file: String
    
    public var fileName: String {
        return String(
            file
                .split(separator: "/")
                .last!
        )
    }
    
    @Option(help: "The id of the app that should be updated.")
    public var appId: Int
    
    @Flag(help: "Log extensive debug information (network calls).")
    public var verbose: Bool = false
    
    private func session() -> Session<OPClient> {
        let client = OPClient(
            baseURL: URL(string: "https://api.observepoint.com/v2/")!,
            apiKey: apiKey
        )
        let session = Session(with: client)
        session.debug = verbose
        
        return session
    }
    
    private func uploadSession() -> Session<OPClient> {
        let client = OPClient(
            baseURL: URL(string: "https://upload.observepoint.com/v2/")!,
            apiKey: apiKey
        )
        let delegate = ProgressPrintingURLSessionDataDelegate()
        let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let session = Session(with: client, using: urlSession)
        session.debug = verbose
        
        return session
    }
        
    public init() {}
    
    public func run() throws {
        service = UpdateAppService(
            apiKey: apiKey,
            appId: appId,
            fileName: fileName,
            appFileData: try Data(contentsOf: URL(fileURLWithPath: file.expandingTildeInPath)),
            verbose: verbose,
            session: session(),
            uploadSession: uploadSession()
        )
        try service?.updateAppAndTriggerJourneys()
    }
}
