import XCTest
import Combine
import Foundation
import CombineExpectations

/// Tests that Recorder fail tests when they are fed with a subscriber that does
/// not behave correctly, and messes with the Recorder state machine.
///
/// Our goal is to make it clear that the problem with wacky publishers is
/// wacky publishers, not this library.
class WackySubscriberTests: FailureTestCase {
    func testDoubleSubscriptionPublisher() throws {
        struct DoubleSubscriptionPublisher<Base: Publisher>: Publisher {
            typealias Output = Base.Output
            typealias Failure = Base.Failure
            let base: Base
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                base.receive(subscriber: subscriber)
                base.receive(subscriber: subscriber)
            }
        }
        assertFailure("failed - Publisher recorder is already subscribed") {
            let publisher = DoubleSubscriptionPublisher(base: Just("foo").makeConnectable())
            _ = publisher.record()
        }
    }
    
    func testCompletionBeforeSubscriptionPublisher() throws {
        struct CompletionBeforeSubscriptionPublisher: Publisher {
            typealias Output = Never
            typealias Failure = Never
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                subscriber.receive(completion: .finished)
            }
        }
        assertFailure("failed - Publisher recorder got unexpected completion before subscription: finished") {
            let publisher = CompletionBeforeSubscriptionPublisher()
            _ = publisher.record()
        }
    }
    
    func testInputBeforeSubscriptionPublisher() throws {
        struct InputBeforeSubscriptionPublisher: Publisher {
            typealias Output = String
            typealias Failure = Never
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                _ = subscriber.receive("foo")
            }
        }
        assertFailure(#"failed - Publisher recorder got unexpected input before subscription: "foo""#) {
            let publisher = InputBeforeSubscriptionPublisher()
            _ = publisher.record()
        }
    }
    
    func testInputAfterCompletionPublisher() throws {
        struct InputAfterCompletionPublisher<Base: Publisher>: Publisher
            where Base.Output == String
        {
            typealias Output = Base.Output
            typealias Failure = Base.Failure
            let base: Base
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                base.receive(subscriber: subscriber)
                _ = subscriber.receive("bar")
            }
        }
        assertFailure(#"failed - Publisher recorder got unexpected input after completion: "bar""#) {
            let publisher = InputAfterCompletionPublisher(base: Just("foo"))
            _ = publisher.record()
        }
    }
    
    func testDoubleCompletionPublisher() throws {
        struct DoubleCompletionPublisher<Base: Publisher>: Publisher {
            typealias Output = Base.Output
            typealias Failure = Base.Failure
            let base: Base
            func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
                base.receive(subscriber: subscriber)
                subscriber.receive(completion: .finished)
            }
        }
        assertFailure("failed - Publisher recorder got unexpected completion after completion") {
            let publisher = DoubleCompletionPublisher(base: Just("foo"))
            _ = publisher.record()
        }
    }
}
