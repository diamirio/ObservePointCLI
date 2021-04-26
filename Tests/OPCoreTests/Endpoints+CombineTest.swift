import Foundation
import XCTest
import Endpoints
import Combine

@testable import OPCore

final class EndpointsAndCombineTests: XCTestCase {
    
    private class ObservePointCallsResultProvider: FakeResultProvider {
        
        private let fail: Bool
        
        init(fail: Bool = false) {
            self.fail = fail
        }
        
        func resultFor<C>(call: C) -> URLSessionTaskResult where C : Call {
            return URLSessionTaskResult(
                response: FakeHTTPURLResponse(status: fail ? 500 : 200),
                data: nil,
                error: nil
            )
        }
    }
    
    private class AppsSubscriber: Subscriber {
        typealias Input = [StoreApp]
        typealias Failure = Error
        
        func receive(subscription: Subscription) {
            ()
        }
        
        func receive(_ input: [StoreApp]) -> Subscribers.Demand {
            return Subscribers.Demand.none
        }
        
        func receive(completion: Subscribers.Completion<Error>) {
            ()
        }
    }
    
    func testLifecycleOnSuccess() throws {
        let client = OPClient(baseURL: URL(string: "https://tailored-apps.com")!, apiKey: "Test")
        let session = FakeSession(with: client, resultProvider: ObservePointCallsResultProvider())
        
        let publisher: AnyPublisher<[StoreApp], Error> = session
            .publisher(for: OPClient.AppsAPI.Get())
            .eraseToAnyPublisher()
        
        var subscriber: AppsSubscriber? = AppsSubscriber()
        
        publisher.subscribe(subscriber!)
        
        weak var weakSubscriber = subscriber
        subscriber = nil
        
        XCTAssertNil(weakSubscriber)
    }
    
    func testLifecycleOnFailure() throws {
        let client = OPClient(baseURL: URL(string: "https://tailored-apps.com")!, apiKey: "Test")
        let session = FakeSession(with: client, resultProvider: ObservePointCallsResultProvider(fail: true))
        
        let publisher: AnyPublisher<[StoreApp], Error> = session
            .publisher(for: OPClient.AppsAPI.Get())
            .eraseToAnyPublisher()
        
        var subscriber: AppsSubscriber? = AppsSubscriber()
        
        publisher.subscribe(subscriber!)
        
        weak var weakSubscriber = subscriber
        subscriber = nil
        
        XCTAssertNil(weakSubscriber)
    }
}
