import Foundation
import Combine

struct DebugOptions: OptionSet {
    let rawValue: Int
    
    static let output = Self(rawValue: 1 << 0)
    static let subscription = Self(rawValue: 1 << 1)
    static let completion = Self(rawValue: 1 << 2)
    static let cancel = Self(rawValue: 1 << 3)
    static let request = Self(rawValue: 1 << 4)
    
    static let all: Self = [.output, .subscription, .completion, .cancel, .request]
}

extension Publisher {
    func debug(
        options: DebugOptions = [.output],
        file: String = #file,
        line: UInt = #line
    ) -> Publishers.HandleEvents<Self> {
        
        return handleEvents { (subscription) in
            guard options.contains(.subscription) else { return }
            debugPrint(message: "Received Subscription \(subscription)")
            
        } receiveOutput: { (output) in
            guard options.contains(.output) else { return }
            debugPrint(message: "Received Output \(output)")
            
        } receiveCompletion: { (completion) in
            guard options.contains(.completion) else { return }
            debugPrint(message: "Received Completion \(completion)")
            
        } receiveCancel: {
            guard options.contains(.cancel) else { return }
            debugPrint(message: "Received Cancel")
            
        } receiveRequest: { (demand) in
            guard options.contains(.request) else { return }
            debugPrint(message: "Received Demand \(demand)")
        }
    }
    
    func retryWithDelay(
        retries: Int,
        delay: TimeInterval
    ) -> AnyPublisher<Output, Failure> {
        self
            .delayIfFailure(for: delay)
            .retry(retries)
            .eraseToAnyPublisher()
    }

    private func delayIfFailure(
        for delay: TimeInterval
    ) -> AnyPublisher<Output, Failure>  {
        self.catch { error in
            Future { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
