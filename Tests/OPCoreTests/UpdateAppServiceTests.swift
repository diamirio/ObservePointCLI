import Foundation
import Combine
import Endpoints
import XCTest

@testable import OPCore
import CombineExpectations

final class UpdateAppServiceTests: XCTestCase {

    private class WorkflowValidationFakeResultProvider: FakeResultProvider {
        
        enum WorkflowStep {
            case loadApp
            case createUploadForApp
            case uploadApp
            case ensureUploadStateReturnInProgress
            case ensureUploadStateReturnFinished
            case fetchJourneys
            case triggerJourneys(_ pathsToTrigger: Set<String>)
            case finish
        }
        
        struct State {
            let appId = Int.random(in: 200...300)
            let appName = UUID().uuidString
            let folderId = Int.random(in: 0...100)
            let uploadId = UUID().uuidString
            let appJourneys: Set<Int> = [
                Int.random(in: 1000...1100),
                Int.random(in: 2000...2100),
                Int.random(in: 3000...3100),
            ]
            
            var nextExpectedStep: WorkflowStep = .loadApp
            var alreadyLoadedJourneys: Set<Int> = []
        }
        
        private let serialQueue = DispatchQueue(label: "WorkflowValidationFakeResultProviderQueue")
        
        private let finishExpectation: XCTestExpectation
        
        private(set) var state: State = State()
        
        init(finishExpectation: XCTestExpectation) {
            self.finishExpectation = finishExpectation
            
            debugPrint(message: "Running with state '\(state)'")
        }
        
        func resultFor<C>(call: C) -> URLSessionTaskResult where C : Call {
            serialQueue.sync {
                let httpMethod = call.request.urlRequest.httpMethod
                let path = call.request.urlRequest.url!.path
                
                switch state.nextExpectedStep {
                case .loadApp:
                    XCTAssertEqual("GET", httpMethod)
                    XCTAssertEqual("apps/\(state.appId)", path)
                    
                    state.nextExpectedStep = .createUploadForApp
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "id": \(state.appId),
                                "name": "\(state.appName)",
                                "folderId": \(state.folderId),
                                "uploadState": "finished"
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .createUploadForApp:
                    XCTAssertEqual("POST", httpMethod)
                    XCTAssertEqual("apps/\(state.appId)", path)
                    
                    state.nextExpectedStep = .uploadApp
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "uploadId": "\(state.uploadId)"
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .uploadApp:
                    XCTAssertEqual("PUT", httpMethod)
                    XCTAssertEqual("apps/\(state.uploadId)", path)
                    
                    state.nextExpectedStep = .ensureUploadStateReturnInProgress
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "uploadId": "\(state.uploadId)"
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .ensureUploadStateReturnInProgress:
                    XCTAssertEqual("GET", httpMethod)
                    XCTAssertEqual("apps/\(state.uploadId)", path)
                    
                    state.nextExpectedStep = .ensureUploadStateReturnFinished
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "uploadId": "\(state.uploadId)",
                                "app": {
                                    "id": \(state.appId),
                                    "name": "\(state.appName)",
                                    "folderId": \(state.folderId),
                                    "uploadState": "updating"
                                }
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .ensureUploadStateReturnFinished:
                    XCTAssertEqual("GET", httpMethod)
                    XCTAssertEqual("apps/\(state.uploadId)", path)
                    
                    state.nextExpectedStep = .fetchJourneys
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "uploadId": "\(state.uploadId)",
                                "app": {
                                    "id": \(state.appId),
                                    "name": "\(state.appName)",
                                    "folderId": \(state.folderId),
                                    "uploadState": "finished"
                                }
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .fetchJourneys:
                    XCTAssertEqual("GET", httpMethod)
                    XCTAssertEqual("apps/\(state.appId)/app-journeys", path)
                    
                    
                    let triggerPaths = state.appJourneys.map {
                        "app-journeys/\($0)/runs"
                    }
                    state.nextExpectedStep = .triggerJourneys(Set(triggerPaths))
                    
                    let appJouneysJSONString = state.appJourneys.map {
                        """
                        {
                            "id": \($0),
                            "name": "\(UUID().uuidString)"
                        }
                        """
                    }.joined(separator: ",")
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            [\(appJouneysJSONString)]
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case var .triggerJourneys(ids: pathsLeftToTrigger):
                    debugPrint(message: "====")
                    debugPrint(message: "leftToTrigger: \(pathsLeftToTrigger)")
                    debugPrint(message: "path: \(path)")
                    
                    XCTAssertEqual("POST", httpMethod)
                    XCTAssertNotNil(pathsLeftToTrigger.remove(path), "Expected one of \(pathsLeftToTrigger), got \(path)")
                          
                    if pathsLeftToTrigger.isEmpty {
                        state.nextExpectedStep = .finish
                        finishExpectation.fulfill()
                    } else {
                        state.nextExpectedStep = .triggerJourneys(pathsLeftToTrigger)
                    }
                    
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(),
                        data:
                            """
                            {
                                "id": 123,
                                "name": "Test"
                            }
                            """.data(using: .utf8)!,
                        error: nil
                    )
                    
                case .finish:
                    XCTFail("Stop it. I do not expect any requests anymore. \(call)")
                    return URLSessionTaskResult(
                        response: FakeHTTPURLResponse(status: 500),
                        data: nil,
                        error: nil
                    )
                }
            }
            
        }
    }
    
    override func setUp() {
        continueAfterFailure = false
    }

    func testWholeWorkflow() throws {
        let exp = expectation(description: "Workflow should finish")
        
        let client = OPClient(baseURL: URL(string: "https://tailored-apps.com")!, apiKey: "Test")
        let fakeResultProvider = WorkflowValidationFakeResultProvider(finishExpectation: exp)
        let session = FakeSession(with: client, resultProvider: fakeResultProvider)
        
        let service = UpdateAppService(
            apiKey: "TestAPIKey",
            appId: fakeResultProvider.state.appId,
            fileName: "TestFileName",
            appFileData: Data(),
            verbose: true,
            session: session,
            uploadSession: session
        )
        
        try service.updateAppAndTriggerJourneys()
        
        waitForExpectations(timeout: 100)
    }
}
