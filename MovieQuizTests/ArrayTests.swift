import XCTest
@testable import MovieQuiz

class ArrayTests: XCTestCase {
    func testGetValueInRange() throws {
        // Given
        let array = ["x", "y", "z"]
        
        // When
        let value = array[safe: 1]
        
        // Then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, "y")
    }
    
    func testGetValueOutOfRange() throws {
        // Given
        let array = ["x", "y", "z"]
        
        // When
        let value = array[safe: 5]
        
        // Then
        XCTAssertNil(value)
    }
}
