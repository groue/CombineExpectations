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
    
    /// The elements and completion recorded so far.
    public var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
        synchronized { (elements: _elements, completion: _completion) }
    }
    
    private var _elements: [Input] = []
    private var _completion: Subscribers.Completion<Failure>?
    private var completionExpectations: [XCTestExpectation] = []
    private var inputExpectations: [(XCTestExpectation, count: Int)] = []
    private let lock = NSLock()
    private var subscription: Subscription?
    
    /// Use Publisher.record()
    fileprivate init() { }
    
    deinit {
        self.subscription?.cancel()
    }
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
    
    // MARK: - Fulfillment
    
    func fulfillOnInput(_ expectation: XCTestExpectation) {
        let initialCount: Int = synchronized {
            let initialCount = min(expectation.expectedFulfillmentCount, _elements.count)
            let remainingCount = expectation.expectedFulfillmentCount - initialCount
            if remainingCount > 0 {
                if _completion == nil {
                    inputExpectations.append((expectation, count: remainingCount))
                    return initialCount
                } else {
                    return expectation.expectedFulfillmentCount
                }
            } else {
                return initialCount
            }
        }
        for _ in 0..<initialCount {
            expectation.fulfill()
        }
    }
    
    func fulfillOnCompletion(_ expectation: XCTestExpectation) {
        synchronized {
            if _completion != nil {
                expectation.fulfill()
            } else {
                completionExpectations.append(expectation)
            }
        }
    }
    
    // MARK: - Subscriber
    
    public func receive(subscription: Subscription) {
        synchronized {
            self.subscription = subscription
        }
        subscription.request(.unlimited)
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        let fulfilledExpectations: [XCTestExpectation] = synchronized {
            guard subscription != nil else { return [] }
            var fulfilledExpectations: [XCTestExpectation] = []
            var nextInputExpectations: [(XCTestExpectation, count: Int)] = []
            for (expectation, count) in inputExpectations {
                assert(count > 0)
                fulfilledExpectations.append(expectation)
                if count > 1 {
                    nextInputExpectations.append((expectation, count: count - 1))
                }
            }
            self._elements.append(input)
            self.inputExpectations = nextInputExpectations
            return fulfilledExpectations
        }
        for expectation in fulfilledExpectations {
            expectation.fulfill()
        }
        return .unlimited
    }
    
    public func receive(completion: Subscribers.Completion<Failure>) {
        let fulfilledExpectations: [(XCTestExpectation, count: Int)] = synchronized {
            var fulfilledExpectations: [(XCTestExpectation, count: Int)] = []
            fulfilledExpectations.append(contentsOf: completionExpectations.map { ($0, count: 1) })
            fulfilledExpectations.append(contentsOf: inputExpectations)
            self._completion = completion
            self.completionExpectations = []
            self.inputExpectations = []
            self.subscription = nil
            return fulfilledExpectations
        }
        for (expectation, count) in fulfilledExpectations {
            for _ in 0..<count {
                expectation.fulfill()
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
