import Combine
import XCTest

/// A Combine subscriber which records all events published by a publisher.
///
/// You create a Recorder with the `Publisher.record()` method:
///
///     let publisher = ["foo", "bar", "baz"].publisher
///     let recorder = publisher.record()
///
/// You can build publisher expectations from the Recorder. For example:
///
///     let elements = try wait(for: recorder.elements, timeout: 1)
///     XCTAssertEqual(elements, ["foo", "bar", "baz"])
public class Recorder<Input, Failure: Error>: Subscriber {
    public typealias Input = Input
    public typealias Failure = Failure
    
    private struct Expectations {
        var onInput: [(XCTestExpectation, remainingCount: Int)] = []
        var onCompletion: [XCTestExpectation] = []
    }
    
    private enum State {
        case waitingForSubscription(Expectations)
        case subscribed(Expectations, [Input], Subscription)
        case completed([Input], Subscribers.Completion<Failure>)
    }
    
    private let lock = NSLock()
    private var state: State = .waitingForSubscription(Expectations())
    
    /// The elements and completion recorded so far.
    public var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
        synchronized {
            switch state {
            case .waitingForSubscription:
                return (elements: [], completion: nil)
            case let .subscribed(_, elements, _):
                return (elements: elements, completion: nil)
            case let .completed(elements, completion):
                return (elements: elements, completion: completion)
            }
        }
    }
    
    /// Use Publisher.record()
    fileprivate init() { }
    
    deinit {
        if case let .subscribed(_, _, subscription) = state {
            subscription.cancel()
        }
    }
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
    
    // MARK: - Fulfillment
    
    func fulfillOnInput(_ expectation: XCTestExpectation) {
        synchronized {
            switch state {
            case let .waitingForSubscription(expectations):
                var expectations = expectations
                expectations.onInput.append((expectation, remainingCount: expectation.expectedFulfillmentCount))
                state = .waitingForSubscription(expectations)
                
            case let .subscribed(expectations, elements, subscription):
                let fulfillmentCount = min(expectation.expectedFulfillmentCount, elements.count)
                expectation.fulfill(count: fulfillmentCount)
                
                let remainingCount = expectation.expectedFulfillmentCount - fulfillmentCount
                if remainingCount > 0 {
                    var expectations = expectations
                    expectations.onInput.append((expectation, remainingCount: remainingCount))
                    state = .subscribed(expectations, elements, subscription)
                }
                
            case .completed:
                expectation.fulfill(count: expectation.expectedFulfillmentCount)
            }
        }
    }
    
    func fulfillOnCompletion(_ expectation: XCTestExpectation) {
        synchronized {
            switch state {
            case let .waitingForSubscription(expectations):
                var expectations = expectations
                expectations.onCompletion.append(expectation)
                state = .waitingForSubscription(expectations)
                
            case let .subscribed(expectations, elements, subscription):
                var expectations = expectations
                expectations.onCompletion.append(expectation)
                state = .subscribed(expectations, elements, subscription)
                
            case .completed:
                expectation.fulfill()
            }
        }
    }
    
    // MARK: - Subscriber
    
    public func receive(subscription: Subscription) {
        synchronized {
            switch state {
            case let .waitingForSubscription(expectations):
                state = .subscribed(expectations, [], subscription)
            default:
                XCTFail("Publisher recorder is already subscribed")
            }
        }
        subscription.request(.unlimited)
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        return synchronized {
            switch state {
            case let .subscribed(expectations, elements, subscription):
                var inputExpectations: [(XCTestExpectation, remainingCount: Int)] = []
                for (expectation, remainingCount) in expectations.onInput {
                    assert(remainingCount > 0)
                    expectation.fulfill()
                    if remainingCount > 1 {
                        inputExpectations.append((expectation, remainingCount: remainingCount - 1))
                    }
                }
                
                var elements = elements
                var expectations = expectations
                elements.append(input)
                expectations.onInput = inputExpectations
                state = .subscribed(expectations, elements, subscription)
                return .unlimited
                
            case .waitingForSubscription:
                XCTFail("Publisher recorder got unexpected input before subscription: \(String(reflecting: input))")
                return .none
                
            case .completed:
                XCTFail("Publisher recorder got unexpected input after completion: \(String(reflecting: input))")
                return .none
            }
        }
    }
    
    public func receive(completion: Subscribers.Completion<Failure>) {
        synchronized {
            switch state {
            case let .subscribed(expectations, elements, _):
                for (expectation, count) in expectations.onInput {
                    expectation.fulfill(count: count)
                }
                for expectation in expectations.onCompletion {
                    expectation.fulfill()
                }
                state = .completed(elements, completion)
                
            case .waitingForSubscription:
                XCTFail("Publisher recorder got unexpected completion before subscription: \(String(describing: completion))")
                
            case .completed:
                XCTFail("Publisher is already completed")
            }
        }
    }
}

extension Publisher {
    /// Returns a subscribed Recorder.
    ///
    /// For example:
    ///
    ///     let publisher = ["foo", "bar", "baz"].publisher
    ///     let recorder = publisher.record()
    ///
    /// You can build publisher expectations from the Recorder. For example:
    ///
    ///     let elements = try wait(for: recorder.elements, timeout: 1)
    ///     XCTAssertEqual(elements, ["foo", "bar", "baz"])
    public func record() -> Recorder<Output, Failure> {
        let recorder = Recorder<Output, Failure>()
        subscribe(recorder)
        return recorder
    }
}

extension XCTestExpectation {
    fileprivate func fulfill(count: Int) {
        for _ in 0..<count {
            fulfill()
        }
    }
}
