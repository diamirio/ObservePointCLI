import Foundation
import Combine
import XCTest

@testable import OPCore
import CombineExpectations

final class PublisherExtensionTests: XCTestCase {

    func testRetryDoesRetryAtLeastAsOftenAsSpecifiedAndSendsCorrectAmountOfElements() throws {
        let publisher = FailXTimesThenPublishXTimesPublisher(fails: 2, publishes: 1)
            .retry(3)
        
        let recorder = publisher.record()
        let elements = try wait(for: recorder.elements, timeout: 5)
        
        XCTAssertEqual(1, elements.count)
    }
    
    func testRetryDelayedDoesRetryAtLeastAsOftenAsSpecifiedAndSendsCorrectAmountOfElements() throws {
        let publisher = FailXTimesThenPublishXTimesPublisher(fails: 1, publishes: 2)
            .retryWithDelay(retries: 5, delay: 0.2)
        
        let recorder = publisher.record()
        let elements = try wait(for: recorder.elements, timeout: 0.5)
        
        XCTAssertEqual(2, elements.count)
    }
    
    func testRetryDelayedDoesNotDelayNonFailures() throws {
        let publisher = FailXTimesThenPublishXTimesPublisher(fails: 1, publishes: 2)
            .retryWithDelay(retries: 5, delay: 0.2)
        
        let recorder = publisher.record()
        let elements = try wait(for: recorder.elements, timeout: 0.3)
        
        XCTAssertEqual(2, elements.count, "Delay should only happen after failure, therefore, we should receive ALL elements")
    }
    
    func testRetryDelayedDoesIndeedDelay() throws {
        let publisher = FailXTimesThenPublishXTimesPublisher(fails: 2, publishes: 1)
            .retryWithDelay(retries: 5, delay: 0.6)
        
        let recorder = publisher.record()
        let elements = try wait(for: recorder.availableElements, timeout: 1)
        
        XCTAssertEqual(0, elements.count, "No element should be retrieved after 1 second if two failures are sent --> 2x delay should be greater than the timeout")
    }
}
