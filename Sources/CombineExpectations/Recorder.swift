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
        case subscribed(Subscription, Expectations, [Input])
        case completed([Input], Subscribers.Completion<Failure>)
        
        var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
            switch self {
            case .waitingForSubscription:
                return (elements: [], completion: nil)
            case let .subscribed(_, _, elements):
                return (elements: elements, completion: nil)
            case let .completed(elements, completion):
                return (elements: elements, completion: completion)
            }
        }
    }
    
    private let lock = NSLock()
    private var state = State.waitingForSubscription(Expectations())
    private var consumedCount = 0
    
    /// The elements and completion recorded so far.
    public var elementsAndCompletion: (elements: [Input], completion: Subscribers.Completion<Failure>?) {
        synchronized {
            state.elementsAndCompletion
        }
    }
    
    /// Use Publisher.record()
    fileprivate init() { }
    
    deinit {
        if case let .subscribed(subscription, _, _) = state {
            subscription.cancel()
        }
    }
    
    private func synchronized<T>(_ execute: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try execute()
    }
    
    // MARK: - PublisherExpectation API
    
    func fulfillOnInput(_ expectation: XCTestExpectation) {
        synchronized {
            switch state {
            case let .waitingForSubscription(expectations):
                var expectations = expectations
                expectations.onInput.append((expectation, remainingCount: expectation.expectedFulfillmentCount))
                state = .waitingForSubscription(expectations)
                
            case let .subscribed(subscription, expectations, elements):
                let fulfillmentCount = min(expectation.expectedFulfillmentCount, elements.count)
                expectation.fulfill(count: fulfillmentCount)
                
                let remainingCount = expectation.expectedFulfillmentCount - fulfillmentCount
                if remainingCount > 0 {
                    var expectations = expectations
                    expectations.onInput.append((expectation, remainingCount: remainingCount))
                    state = .subscribed(subscription, expectations, elements)
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
                
            case let .subscribed(subscription, expectations, elements):
                var expectations = expectations
                expectations.onCompletion.append(expectation)
                state = .subscribed(subscription, expectations, elements)
                
            case .completed:
                expectation.fulfill()
            }
        }
    }
    
    func expectationValue<T>(_ value: (_ elements: [Input], _ completion: Subscribers.Completion<Failure>?, _ remaining: ArraySlice<Input>, _ consume: (Int) -> ()) throws -> T) rethrows -> T {
        try synchronized {
            let (elements, completion) = state.elementsAndCompletion
            let remaining = elements[consumedCount...]
            return try value(elements, completion, remaining, { count in
                precondition(count >= 0)
                precondition(count <= remaining.count)
                consumedCount += count
            })
        }
    }
    
    // MARK: - Subscriber
    
    public func receive(subscription: Subscription) {
        synchronized {
            switch state {
            case let .waitingForSubscription(expectations):
                state = .subscribed(subscription, expectations, [])
            default:
                XCTFail("Publisher recorder is already subscribed")
            }
        }
        subscription.request(.unlimited)
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        return synchronized {
            switch state {
            case let .subscribed(subscription, expectations, elements):
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
                state = .subscribed(subscription, expectations, elements)
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
            case let .subscribed(_, expectations, elements):
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

// MARK: - Publisher Expectations

extension PublisherExpectations {
    /// The type of the publisher expectation returned by Recorder.completion
    public typealias Completion<Input, Failure: Error> = Map<Recording<Input, Failure>, Subscribers.Completion<Failure>>
    
    /// The type of the publisher expectation returned by Recorder.elements
    public typealias Elements<Input, Failure: Error> = Map<Recording<Input, Failure>, [Input]>
    
    /// The type of the publisher expectation returned by Recorder.last
    public typealias Last<Input, Failure: Error> = Map<Elements<Input, Failure>, Input?>
    
    /// The type of the publisher expectation returned by Recorder.single
    public typealias Single<Input, Failure: Error> = Map<Elements<Input, Failure>, Input>
}

extension Recorder {
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time.
    ///
    /// Otherwise, a [Subscribers.Completion](https://developer.apple.com/documentation/combine/subscribers/completion)
    /// is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherCompletesWithSuccess() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let completion = try wait(for: recorder.completion, timeout: 1)
    ///         if case let .failure(error) = completion {
    ///             XCTFail("Unexpected error \(error)")
    ///         }
    ///     }
    public var completion: PublisherExpectations.Completion<Input, Failure> {
        recording.map { $0.completion }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time, and the publisher
    /// error is thrown if the publisher fails.
    ///
    /// Otherwise, an array of published elements is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherPublishesArrayElements() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.elements, timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
    ///     }
    public var elements: PublisherExpectations.Elements<Input, Failure> {
        recording.map { recording in
            if case let .failure(error) = recording.completion {
                throw error
            }
            return recording.output
        }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, the publisher error is thrown if the
    /// publisher fails.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherFinishesWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.finished, timeout: 1)
    ///     }
    ///
    /// This publisher expectation can be inverted:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotFinish() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.finished.inverted, timeout: 1)
    ///     }
    public var finished: PublisherExpectations.Finished<Input, Failure> {
        PublisherExpectations.Finished(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, the publisher error is thrown if the
    /// publisher fails before publishing any element.
    ///
    /// Otherwise, the first published element is returned, or nil if the publisher
    /// completes before it publishes any element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesItsFirstElementWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         if let element = try wait(for: recorder.first, timeout: 1) {
    ///             XCTAssertEqual(element, "foo")
    ///         } else {
    ///             XCTFail("Expected one element")
    ///         }
    ///     }
    ///
    /// This publisher expectation can be inverted:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.first.inverted, timeout: 1)
    ///     }
    public var first: PublisherExpectations.First<Input, Failure> {
        PublisherExpectations.First(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time, and the publisher
    /// error is thrown if the publisher fails.
    ///
    /// Otherwise, the last published element is returned, or nil if the publisher
    /// completes before it publishes any element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherPublishesLastElementLast() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         if let element = try wait(for: recorder.last, timeout: 1) {
    ///             XCTAssertEqual(element, "baz")
    ///         } else {
    ///             XCTFail("Expected one element")
    ///         }
    ///     }
    public var last: PublisherExpectations.Last<Input, Failure> {
        elements.map { $0.last }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not publish one element after last waited expectation.
    /// The publisher error is thrown if the publisher fails before
    /// publishing one element.
    ///
    /// Otherwise, the next published element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfTwoElementsPublishesElementsInOrder() throws {
    ///         let publisher = ["foo", "bar"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "foo")
    ///
    ///         element = try wait(for: recorder.next(), timeout: 1)
    ///         XCTAssertEqual(element, "bar")
    ///     }
    public func next() -> PublisherExpectations.NextOne<Input, Failure> {
        PublisherExpectations.NextOne(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit `count` elements, or to complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not publish `count` elements after last waited
    /// expectation. The publisher error is thrown if the publisher fails before
    /// publishing `count` elements.
    ///
    /// Otherwise, an array of exactly `count` element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var elements = try wait(for: recorder.next(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///
    ///         elements = try wait(for: recorder.next(1), timeout: 1)
    ///         XCTAssertEqual(elements, ["baz"])
    ///     }
    ///
    /// - parameter count: The number of elements.
    public func next(_ count: Int) -> PublisherExpectations.Next<Input, Failure> {
        PublisherExpectations.Next(recorder: self, count: count)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit `maxLength` elements, or to complete.
    ///
    /// When waiting for this expectation, the publisher error is thrown if the
    /// publisher fails before `maxLength` elements are published.
    ///
    /// Otherwise, an array of received elements is returned, containing at
    /// most `maxLength` elements, or less if the publisher completes early.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.prefix(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///     }
    ///
    /// This publisher expectation can be inverted:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectPublishesNoMoreThanSentValues() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         publisher.send("foo")
    ///         publisher.send("bar")
    ///         let elements = try wait(for: recorder.prefix(3).inverted, timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///     }
    ///
    /// - parameter maxLength: The maximum number of elements.
    public func prefix(_ maxLength: Int) -> PublisherExpectations.Prefix<Input, Failure> {
        PublisherExpectations.Prefix(recorder: self, maxLength: maxLength)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time.
    ///
    /// Otherwise, a [Record.Recording](https://developer.apple.com/documentation/combine/record/recording)
    /// is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherRecording() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let recording = try wait(for: recorder.recording, timeout: 1)
    ///         XCTAssertEqual(recording.output, ["foo", "bar", "baz"])
    ///         if case let .failure(error) = recording.completion {
    ///             XCTFail("Unexpected error \(error)")
    ///         }
    ///     }
    public var recording: PublisherExpectations.Recording<Input, Failure> {
        PublisherExpectations.Recording(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not complete on time, or does not publish exactly one
    /// element before it completes. The publisher error is thrown if the
    /// publisher fails.
    ///
    /// Otherwise, the single published element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testJustPublishesExactlyOneElement() throws {
    ///         let publisher = Just("foo")
    ///         let recorder = publisher.record()
    ///         let element = try wait(for: recorder.single, timeout: 1)
    ///         XCTAssertEqual(element, "foo")
    ///     }
    public var single: PublisherExpectations.Single<Input, Failure> {
        elements.map { elements in
            guard let element = elements.first else {
                throw RecordingError.notEnoughElements
            }
            if elements.count > 1 {
                throw RecordingError.tooManyElements
            }
            return element
        }
    }
}

// MARK: - Publisher + Recorder

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

// MARK: - Convenience

extension XCTestExpectation {
    fileprivate func fulfill(count: Int) {
        for _ in 0..<count {
            fulfill()
        }
    }
}
