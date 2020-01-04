import XCTest
import Combine
import Foundation
@testable import CombineExpectations

/// Tests for subscribers that do not create subscriptions right when they
/// receive subscribers.
class LateSubscriptionTest: FailureTestCase {
    func testNoSubscriptionPublisher() throws {
        struct NoSubscriptionPublisher: Publisher {
            typealias Output = String
            typealias Failure = Never
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input { }
        }

        do {
            let publisher = NoSubscriptionPublisher()
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertTrue(elements.isEmpty)
            XCTAssertNil(completion)
        }
        do {
            // a test with an expectation that is fulfilled on completion
            let publisher = NoSubscriptionPublisher()
            let recorder = publisher.record()
            
            try wait(for: recorder.finished.inverted, timeout: 0.1)
        }
        do {
            // a test with an expectation that is fulfilled on input
            let publisher = NoSubscriptionPublisher()
            let recorder = publisher.record()
            
            try wait(for: recorder.next().inverted, timeout: 0.1)
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
            // a test with an expectation that is fulfilled on completion
            let publisher = AsynchronousSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            try wait(for: recorder.finished, timeout: 0.1)
        }
        do {
            // a test with an expectation that is fulfilled on input
            let publisher = AsynchronousSubscriptionPublisher(base: Just("foo"))
            let recorder = publisher.record()
            
            let element = try wait(for: recorder.next(), timeout: 0.1)
            XCTAssertEqual(element, "foo")
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, ["foo"])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
    }
}
