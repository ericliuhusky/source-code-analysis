import Darwin.POSIX.pthread.pthread

func threadStart(_ context: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    let thread = unsafeBitCast(context, to: Thread.self)
    thread.main()
    return nil
}

public class Thread {
    var _main: () -> Void = {}
    var _thread: pthread_t!
        
    public init(block: @escaping () -> Void) {
        _main = block
    }
    
    public func start() {
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        var thread: pthread_t!
        pthread_create(&thread, nil, threadStart, selfPtr);
        _thread = thread
    }
    
    func main() {
        _main()
    }
    
    public func join() {
        pthread_join(_thread, nil)
    }
}
