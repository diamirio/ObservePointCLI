import Foundation
import Combine
import Endpoints

class UpdateAppService {
    
    private let apiKey: String
    private let appId: Int
    private let fileName: String
    private let appFileData: Data
    private let verbose: Bool
    
    private var cancellables = Set<AnyCancellable>()
        
    private let debugOptions: DebugOptions = [.output]
    
    private let session: Session<OPClient>
    
    private let uploadSession: Session<OPClient>
    
    init(
        apiKey: String,
        appId: Int,
        fileName: String,
        appFileData: Data,
        verbose: Bool,
        session: Session<OPClient>,
        uploadSession: Session<OPClient>
    ) {
        self.apiKey = apiKey
        self.appId = appId
        self.fileName = fileName
        self.appFileData = appFileData
        self.verbose = verbose
        self.session = session
        self.uploadSession = uploadSession
    }
    
    func updateAppAndTriggerJourneys() throws {
        Publishers
            .app(with: appId, using: session).debug(options: debugOptions)
            .createNewUploadForApp(fileName: fileName, using: session).debug(options: debugOptions)
            .uploadAppFile(data: appFileData, using: uploadSession)
            .ensureUploadState(using: session).debug(options: debugOptions)
            .fetchAppJourneys(appId: appId, using: session).debug(options: debugOptions)
            .triggerJourneys(using: session).debug(options: debugOptions)
            .sink { (completion) in
                switch completion {
                case let .failure(error):
                    debugPrint(message: "============ ERROR ============")
                    debugPrint(message: "\(error)")
                    debugPrint(message: "============ ERROR ============")
                    Darwin.exit(EXIT_FAILURE)

                case .finished:
                    debugPrint(message: "My job is done. Bye.")
                    Darwin.exit(EXIT_SUCCESS)
                }

            } receiveValue: { (appJourneys: [AppJourney]) in
                let journeyNames = appJourneys
                    .map(\.name)
                    .joined(separator: ", ")
                let journeyNamesInfo =  journeyNames.isEmpty ? "No journeys found for app" : journeyNames
                
                debugPrint(message: "Successfully uploaded your app and triggered journeys:\n\(journeyNamesInfo)")
            }
            .store(in: &cancellables)
    }
}


private extension Publishers {
    static func app(
        with id: Int,
        using session: Session<OPClient>
    ) -> AnyPublisher<StoreApp, Error> {
        return session.publisher(for: OPClient.AppsAPI.GetById(id: id))
            .mapError { CLIError.retrievingAppInfoFailed(id: id, $0) }
            .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == StoreApp, Failure == Error {
    func createNewUploadForApp(
        fileName: String,
        using session: Session<OPClient>
    ) -> AnyPublisher<MobileAppUpload, Error> {
        
        return flatMap { (app: StoreApp) -> AnyPublisher<MobileAppUpload, Error> in
            let call = OPClient.AppsAPI.CreateUploadId(
                ExistingMobileApp(
                    id: app._id,
                    name: app.name,
                    file: fileName,
                    platform: Platform.iOS,
                    folderId: app.folderId
                )
            )

            return session.publisher(for: call)
                .mapError { CLIError.createAppFailed($0) }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

private extension Publisher where Output == MobileAppUpload, Failure == Error {
    func uploadAppFile(
        data appFileData: Data,
        using session: Session<OPClient>
    ) -> AnyPublisher<MobileAppUpload, Error> {
        
        return flatMap { (mobileAppUpload: MobileAppUpload) -> AnyPublisher<MobileAppUpload, Error> in
            let call = OPClient.AppsAPI.UploadFile(
                mobileAppUpload,
                appFileData: appFileData
            )
            
            return session.publisher(for: call)
                .mapError { CLIError.uploadAppFileFailed($0) }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

private extension Publisher where Output == MobileAppUpload, Failure == Error {
    func ensureUploadState(
        state: StoreApp.UploadState = StoreApp.UploadState.finished,
        retries: Int = 40,
        delayForRetries: TimeInterval = 2,
        using session: Session<OPClient>
    ) -> AnyPublisher<MobileAppUploadStatus, Error> {
        
        return flatMap { (mobileAppUpload: MobileAppUpload) -> AnyPublisher<MobileAppUploadStatus, Error> in
            let call = OPClient.AppsAPI.CheckUploadState(upload: mobileAppUpload)
            
            return session.publisher(for: call)
                .mapError { (error: Error) -> Error in
                    debugPrint(message: "Unexpected Error: \(error). If it has not happened too often, I will  retry.")
                    return error
                }
                .tryMap {
                    guard $0.app?.uploadState == state else {
                        throw CLIError.wrongUploadState(expected: state, actual: $0.app?.uploadState)
                    }
                    
                    return $0
                }
                .retryWithDelay(
                    retries: retries,
                    delay: delayForRetries
                )
                .mapError { CLIError.checkingUploadStateFailed($0) }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

private extension Publisher where Failure == Error {
    func fetchAppJourneys(
        appId: Int,
        using session: Session<OPClient>
    ) -> AnyPublisher<[AppJourney], Error> {
        return flatMap { (_) -> AnyPublisher<[AppJourney], Error> in
            let call = OPClient.AppsAPI.JourneysForApp(id: appId)
            
            return session.publisher(for: call)
                .mapError { CLIError.retrievingAppJourneysForAppFailed(appId: appId, $0) }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

private extension Publisher where Output == [AppJourney], Failure == Error {
    func triggerJourneys(
        retries: Int = 10,
        using session: Session<OPClient>
    ) -> AnyPublisher<Output, Failure> {
        
        return flatMap { (appJourneys: [AppJourney]) -> AnyPublisher<Output, Failure> in
            
            let publishers = appJourneys.map { (journey: AppJourney) -> AnyPublisher<Output.Element, Failure> in
                
                let call = OPClient.AppJourneysAPI.Run(id: journey._id)
                return session
                    .publisher(for: call)

                    .retry(retries)
                    .eraseToAnyPublisher()
            }
            
            return publishers
                .publisher
                .flatMap { $0 }
                .collect()
                .mapError { CLIError.triggeringAllAppJourneysFailed($0) }
                .eraseToAnyPublisher()
            
        }.eraseToAnyPublisher()
    }
}
