import XCTest

/// The protocol for publisher expectations that can be inverted.
public protocol InvertablePublisherExpectation: PublisherExpectation { }

extension PublisherExpectations {
    /// A publisher expectation that fails if the base expectation is fulfilled.
    ///
    /// When waiting for this expectation, you receive the same result and
    /// eventual error as the base expectation.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotFinish() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.finished.inverted, timeout: 1)
    ///     }
    public struct Inverted<Base: PublisherExpectation>: InvertablePublisherExpectation {
        let base: Base
        
        public func _setup(_ expectation: XCTestExpectation) {
            base._setup(expectation)
            expectation.isInverted.toggle()
        }
        
        public func _value() throws -> Base.Output {
            try base._value()
        }
    }
}

extension InvertablePublisherExpectation {
    /// Returns an inverted expectation which fails if the base expectation
    /// fulfills within the specified timeout.
    ///
    /// When waiting for an inverted expectation, you receive the same result
    /// and eventual error as the base expectation.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotFinish() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.finished.inverted, timeout: 1)
    ///     }
    public var inverted: PublisherExpectations.Inverted<Self> {
        PublisherExpectations.Inverted(base: self)
    }
}
