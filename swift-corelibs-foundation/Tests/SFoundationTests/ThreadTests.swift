import XCTest
@testable import SFoundation

final class ThreadTests: XCTestCase {
    func testDataRace() throws {
        var a = 0
        
        var threads = [SFoundation.Thread]()
        for _ in 0..<3 {
            let thread = SFoundation.Thread {
                let temp = a + 1
                Thread.sleep(forTimeInterval: 0.01)
                a = temp
            }
            thread.start()
            threads.append(thread)
        }
        
        for thread in threads {
            thread.join()
        }
        
        XCTAssertEqual(a, 1)
    }
}
