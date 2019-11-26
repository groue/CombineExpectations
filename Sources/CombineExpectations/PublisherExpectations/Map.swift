import XCTest

extension PublisherExpectations {
    /// A publisher expectation that transforms the value of a base expectation.
    ///
    /// This expectation has no public initializer.
    public struct Map<Base: PublisherExpectation, Output>: PublisherExpectation {
        let base: Base
        let transform: (Base.Output) throws -> Output
        
        public func setup(_ expectation: XCTestExpectation) {
            base.setup(expectation)
        }
        
        public func expectedValue() throws -> Output {
            try transform(base.expectedValue())
        }
    }
}

extension PublisherExpectation {
    /// Returns a publisher expectation that transforms the value of the
    /// base expectation.
    func map<T>(_ transform: @escaping (Output) throws -> T) -> PublisherExpectations.Map<Self, T> {
        PublisherExpectations.Map(base: self, transform: transform)
    }
}
