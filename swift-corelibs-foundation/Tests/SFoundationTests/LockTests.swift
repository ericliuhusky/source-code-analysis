import XCTest
@testable import SFoundation

final class LockTests: XCTestCase {
    func testLock() throws {
        let lock = Lock()
        
        var a = 0
        
        var threads = [SFoundation.Thread]()
        for _ in 0..<3 {
            let thread = SFoundation.Thread {
                lock.lock()
                let temp = a + 1
                Thread.sleep(forTimeInterval: 0.01)
                a = temp
                lock.unlock()
            }
            thread.start()
            threads.append(thread)
        }
        
        for thread in threads {
            thread.join()
        }
        
        XCTAssertEqual(a, 3)
    }
}
