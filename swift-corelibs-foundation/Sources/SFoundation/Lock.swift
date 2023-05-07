import Darwin.POSIX.pthread.pthread

public protocol Locking {
    func lock()
    func unlock()
}

public extension Locking {
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }
        return try body()
    }
}

public class Lock: Locking {
    let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
    public init() {
        pthread_mutex_init(mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }
    
    public func lock() {
        pthread_mutex_lock(mutex)
    }
    
    public func unlock() {
        pthread_mutex_unlock(mutex)
    }
}
