import Combine

extension Publisher where Failure == Never {
    /// Returns a publisher which completes with an error.
    func append<Failure: Error>(error: Failure) -> AnyPublisher<Output, Failure> {
        setFailureType(to: Failure.self)
            .append(Fail(error: error))
            .eraseToAnyPublisher()
    }
}
