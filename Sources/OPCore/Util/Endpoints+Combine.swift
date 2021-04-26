import Foundation
import Combine
import Endpoints

extension Session {
    func publisher<C: Call>(for call: C) -> AnyPublisher<C.Parser.OutputType, Error> {
        return EndpointsPublisher(session: self, call: call).eraseToAnyPublisher()
    }
}

struct EndpointsPublisher<_Client: Client, _Session: Session<_Client>, _Call: Call>: Publisher {
    typealias Output = _Call.Parser.OutputType
    typealias Failure = Error
    
    let session: _Session
    let call: _Call
    
    func receive<_Subscriber>(subscriber: _Subscriber) where _Subscriber: Subscriber, Self.Failure == _Subscriber.Failure, Self.Output == _Subscriber.Input {
        subscriber.receive(subscription: EndpointsSubscription(subscriber: subscriber, session: session, call: call))
    }
}

private class EndpointsSubscription<_Client: Client, _Session: Session<_Client>, _Call: Call, _Subscriber: Subscriber>: Subscription
where
    _Subscriber.Input == _Call.Parser.OutputType,
    _Subscriber.Failure == Error
{
    private var subscriber: _Subscriber?
    private let session: _Session
    private let call: _Call
    
    private var dataTask: URLSessionDataTask?
    
    init(subscriber: _Subscriber, session: _Session, call: _Call) {
        self.subscriber = subscriber
        self.session = session
        self.call = call
    }
    
    func request(_ demand: Subscribers.Demand) {
        dataTask = session.start(call: call) { result in
            result.onSuccess { [weak self] response in
                _ = self?.subscriber?.receive(response)
                self?.subscriber?.receive(completion: .finished)
                self?.subscriber = nil
            }
            .onError { [weak self] error in
                self?.subscriber?.receive(completion: .failure(error))
            }
        }
    }
    
    func cancel() {
        dataTask?.cancel()
        dataTask = nil
        subscriber = nil
    }
}

