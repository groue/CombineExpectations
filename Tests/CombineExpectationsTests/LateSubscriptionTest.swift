import XCTest
import Combine
import Foundation
import CombineExpectations

/// Tests for subscribers that do not create subscriptions right when they
/// receive subscribers.
class LateSubscriptionTest: FailureTestCase {
    func testNoSubscriptionPublisher() throws {
        struct NoSubscriptionPublisher<Base: Publisher>: Publisher {
            typealias Output = Base.Output
            typealias Failure = Base.Failure
            let base: Base
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input { }
        }

        do {
            let publisher = NoSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertTrue(elements.isEmpty)
            XCTAssertNil(completion)
        }
        do {
            let publisher = NoSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            try wait(for: recorder.finished.inverted, timeout: 0.1)
        }
        do {
            let publisher = NoSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            _ = try wait(for: recorder.first.inverted, timeout: 0.1)
        }
    }
    
    func testAsynchronousSubscriptionPublisher() throws {
        struct AsynchronousSubscriptionPublisher<Base: Publisher>: Publisher {
            typealias Output = Base.Output
            typealias Failure = Base.Failure
            let base: Base
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                DispatchQueue.main.async {
                    self.base.receive(subscriber: subscriber)
                }
            }
        }
        
        do {
            let publisher = AsynchronousSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertTrue(elements.isEmpty)
            XCTAssertNil(completion)
        }
        do {
            let publisher = AsynchronousSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            try wait(for: recorder.finished, timeout: 0.1)
        }
        do {
            let publisher = AsynchronousSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            let element = try wait(for: recorder.first, timeout: 0.1)
            XCTAssertEqual(element, "foo")
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, ["foo"])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
    }
}
