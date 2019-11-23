import XCTest
import Combine
import Foundation
import CombineExpectations

class RecorderTests: XCTestCase {
    private struct TestError: Error { }
    
    // MARK: - Subscription
    
    func testRecorderSubscribes() throws {
        var subscribed = false
        let publisher = Empty<Void, Never>().handleEvents(receiveSubscription: { _ in subscribed = true })
        _ = publisher.record()
        XCTAssertTrue(subscribed)
    }
    
    // MARK: - elementsAndCompletion
    
    func testElementsAndCompletionSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0, 1])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
    }
    
    func testElementsAndCompletionAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0, 1])
            if case let .failure(error) = try XCTUnwrap(completion) { throw error }
        }
    }
    
    func testElementsAndCompletionFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            
            let (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0, 1])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
    }
    
    func testElementsAndCompletionFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            
            var (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [])
            XCTAssertNil(completion)
            
            _ = try wait(for: recorder.completion, timeout: 1)
            (elements, completion) = recorder.elementsAndCompletion
            XCTAssertEqual(elements, [0, 1])
            if case .finished = try XCTUnwrap(completion) {
                XCTFail("Expected TestError")
            }
        }
    }
    
    // MARK: - wait(for: recorder.elements)
    
    func testWaitForElementsSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
    }
    
    func testWaitForElementsAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
    }
    
    func testWaitForElementsFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForElementsFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.elements, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForElementsAndWaitAgain() throws {
        let publisher = (0..<2).publisher
        let recorder = publisher.record()
        let elements = try wait(for: recorder.elements, timeout: 1)
        XCTAssertEqual(elements, [0, 1])
        
        do {
            let elements = try wait(for: recorder.elements, timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
        
        do {
            let elements = try wait(for: recorder.prefix(3), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
        
        do {
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        
        do {
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertEqual(element, 1)
        }
        
        do {
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected RecordingError")
        } catch RecordingError.moreThanOneElement { }
        
        do {
            try wait(for: recorder.finished, timeout: 1)
        }
        
        do {
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
    }
    
    // MARK: - wait(for: recorder.prefix(0))
    
    func testWaitForPrefix0Sync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
    }
    
    func testWaitForPrefix0Async() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        }
    }
    
    func testWaitForPrefix0Failure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
    }
    
    func testWaitForPrefix0FailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(0), timeout: 1)
            XCTAssertEqual(elements, [])
        } catch is TestError { }
    }
    
    // MARK: - wait(for: recorder.prefix(1))
    
    func testWaitForPrefix1Sync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
    }
    
    func testWaitForPrefix1Async() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
    }
    
    func testWaitForPrefix1Failure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(1), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        } catch is TestError { }
    }
    
    func testWaitForPrefix1FailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(1), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1), timeout: 1)
            XCTAssertEqual(elements, [0])
        } catch is TestError { }
    }
    
    func testWaitForPrefix1Inverted() throws {
        do {
            let publisher = Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(1).inverted, timeout: 0.01)
            XCTAssertEqual(elements, [])
        }
    }
    
    // MARK: - wait(for: recorder.prefix(2))
    
    func testWaitForPrefix2Sync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
        do {
            let publisher = (0..<3).publisher
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
    }
    
    func testWaitForPrefix2Async() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
        do {
            let publisher = (0..<3).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        }
    }
    
    func testWaitForPrefix2Failure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(2), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(2), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        } catch is TestError { }
        do {
            let publisher = (0..<3).publisher.append(error: TestError())
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        } catch is TestError { }
    }
    
    func testWaitForPrefix2FailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(2), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.prefix(2), timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        } catch is TestError { }
        do {
            let publisher = (0..<3).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2), timeout: 1)
            XCTAssertEqual(elements, [0, 1])
        } catch is TestError { }
    }
    
    func testWaitForPrefix2Inverted() throws {
        do {
            let publisher = Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2).inverted, timeout: 0.01)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.append(Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main))
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(2).inverted, timeout: 0.01)
            XCTAssertEqual(elements, [0])
        }
    }
    
    // MARK: - wait(for: recorder.prefix(3))
    
    func testWaitForPrefix3Inverted() throws {
        do {
            let publisher = Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main)
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(3).inverted, timeout: 0.01)
            XCTAssertEqual(elements, [])
        }
        do {
            let publisher = (0..<1).publisher.append(Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main))
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(3).inverted, timeout: 0.01)
            XCTAssertEqual(elements, [0])
        }
        do {
            let publisher = (0..<2).publisher.append(Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main))
            let recorder = publisher.record()
            let elements = try wait(for: recorder.prefix(3).inverted, timeout: 0.0)
            XCTAssertEqual(elements, [0, 1])
        }
    }
    
    // MARK: - wait(for: recorder.prefix(N))
    
    func testWaitForPrefixAndWaitForPrefixAgain() throws {
        let publisher = PassthroughSubject<Int, Never>()
        let recorder = publisher.record()
        publisher.send(0)
        try XCTAssertEqual(wait(for: recorder.prefix(1), timeout: 1), [0])
        try XCTAssertEqual(wait(for: recorder.prefix(1), timeout: 1), [0])
        publisher.send(1)
        try XCTAssertEqual(wait(for: recorder.prefix(1), timeout: 1), [0])
        publisher.send(2)
        try XCTAssertEqual(wait(for: recorder.prefix(3), timeout: 1), [0, 1, 2])
    }
    
    func testWaitForPrefixAndWaitForPrefixAgainInverted() throws {
        let publisher = PassthroughSubject<Int, Never>()
        let recorder = publisher.record()
        publisher.send(0)
        try XCTAssertEqual(wait(for: recorder.prefix(1), timeout: 1), [0])
        try XCTAssertEqual(wait(for: recorder.prefix(1), timeout: 1), [0])
        try XCTAssertEqual(wait(for: recorder.prefix(2).inverted, timeout: 0.01), [0])
    }
    
    // MARK: - wait(for: recorder.first)
    
    func testWaitForFirstSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertNil(element)
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        }
    }
    
    func testWaitForFirstAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertNil(element)
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        }
    }
    
    func testWaitForFirstFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.first, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        } catch is TestError { }
    }
    
    func testWaitForFirstFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.first, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first, timeout: 1)
            XCTAssertEqual(element, 0)
        } catch is TestError { }
    }
    
    func testWaitForFirstInverted() throws {
        do {
            let publisher = Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.first.inverted, timeout: 0.01)
            XCTAssertNil(element)
        }
    }
    
    // MARK: - wait(for: recorder.last)
    
    func testWaitForLastSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertNil(element)
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertEqual(element, 1)
        }
    }
    
    func testWaitForLastAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertNil(element)
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.last, timeout: 1)
            XCTAssertEqual(element, 1)
        }
    }
    
    func testWaitForLastFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForLastFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.last, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    // MARK: - wait(for: recorder.single)
    
    func testWaitForSingleSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected RecordingError")
        } catch RecordingError.noElements { }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let element = try wait(for: recorder.single, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected RecordingError")
        } catch RecordingError.moreThanOneElement { }
    }
    
    func testWaitForSingleAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected RecordingError")
        } catch RecordingError.noElements { }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let element = try wait(for: recorder.single, timeout: 1)
            XCTAssertEqual(element, 0)
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected RecordingError")
        } catch RecordingError.moreThanOneElement { }
    }
    
    func testWaitForSingleFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForSingleFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            _ = try wait(for: recorder.single, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    // MARK: - wait(for: recorder.finished)
    
    func testWaitForFinishedSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
    }
    
    func testWaitForFinishedAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
        }
    }
    
    func testWaitForFinishedFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForFinishedFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 1)
            XCTFail("Expected TestError")
        } catch is TestError { }
    }
    
    func testWaitForFinishedInverted() throws {
        do {
            let publisher = Empty<Int, Never>().delay(for: 0.1, scheduler: DispatchQueue.main)
            let recorder = publisher.record()
            try wait(for: recorder.finished.inverted, timeout: 0.01)
        }
    }
    
    // MARK: - wait(for: recorder.completion)
    
    func testWaitForCompletionSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
    }
    
    func testWaitForCompletionAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case let .failure(error) = completion { throw error }
        }
    }
    
    func testWaitForCompletionFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
    }
    
    func testWaitForCompletionFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let completion = try wait(for: recorder.completion, timeout: 1)
            if case .finished = completion {
                XCTFail("Expected TestError")
            }
        }
    }
    
    // MARK: - wait(for: recorder.recording)
    
    func testWaitForRecordingSync() throws {
        do {
            let publisher = Empty<Int, Never>()
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
        do {
            let publisher = (0..<1).publisher
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
        do {
            let publisher = (0..<2).publisher
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0, 1])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func testWaitForRecordingAsync() throws {
        do {
            let publisher = Empty<Int, Never>().receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
        do {
            let publisher = (0..<1).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
        do {
            let publisher = (0..<2).publisher.receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0, 1])
            if case let .failure(error) = recording.completion {
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func testWaitForRecordingFailure() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError())
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError())
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError())
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0, 1])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
    }
    
    func testWaitForRecordingFailureAsync() throws {
        do {
            let publisher = Fail<Int, TestError>(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<1).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
        do {
            let publisher = (0..<2).publisher.append(error: TestError()).receive(on: DispatchQueue.main)
            let recorder = publisher.record()
            let recording = try wait(for: recorder.recording, timeout: 1)
            XCTAssertEqual(recording.output, [0, 1])
            if case .finished = recording.completion {
                XCTFail("Expected TestError")
            }
        }
    }
    
}
