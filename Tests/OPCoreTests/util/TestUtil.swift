import Foundation
import Combine

enum TestError: Error {
    case expected
    case unexpected
}

class Times: ExpressibleByIntegerLiteral, CustomStringConvertible {

    typealias IntegerLiteralType = Int
    
    var amount: IntegerLiteralType
    
    required init(integerLiteral value: IntegerLiteralType) {
        self.amount = value
    }
    
    var description: String {
        return "\(amount)"
    }
}

struct FailXTimesThenPublishXTimesPublisher: Publisher {
    typealias Output = Int
    typealias Failure = Error
    
    let failsLeft: Times
    let publishes: Int

    init(fails: Times, publishes: Int) {
        self.failsLeft = fails
        self.publishes = publishes
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, FailXTimesThenPublishXTimesPublisher.Failure == S.Failure, FailXTimesThenPublishXTimesPublisher.Output == S.Input {
        subscriber.receive(subscription: CustomSubscription(subscriber: subscriber, failsLeft: failsLeft, publishes: publishes))
    }
    
    private class CustomSubscription<S: Subscriber>: Subscription where S.Failure == Error, S.Input == Int {
        private var subscriber: S?
        
        private let failsLeft: Times
        private var publishesLeft: Int

        init(subscriber: S, failsLeft: Times, publishes: Int) {
            self.subscriber = subscriber
            self.failsLeft = failsLeft
            self.publishesLeft = publishes
        }
        
        func request(_ demand: Subscribers.Demand) {
            if failsLeft.amount > 0 {
                failsLeft.amount -= 1

                subscriber?.receive(completion: .failure(TestError.expected))
                subscriber = nil

            } else if publishesLeft > 0 {
                Swift.print("Publishes left: \(publishesLeft)")
                publishesLeft -= 1

                DispatchQueue.main.async {
                    _ = self.subscriber?.receive(1)
                
                }
            } else {
                DispatchQueue.main.async {
                    self.subscriber?.receive(completion: .finished)
                }
            }
        }
        
        func cancel() {
            subscriber = nil
        }
    }
}
