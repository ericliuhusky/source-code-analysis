import Foundation

struct DiskCache {
    private let cacheDirectory: URL
    private let ioQueue: DispatchQueue
    
    init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.hackemist.SDImageCache")
            .appendingPathComponent("default")
        ioQueue = DispatchQueue(label: "com.hackemist.SDImageCache")
    }
    
    func cache(for key: String) -> Data? {
        let fileUrl = cacheFileUrl(for: key)
        let data = try? Data(contentsOf: fileUrl)
        return data
    }
    
    func set(_ cache: Data, for key: String) {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        let fileUrl = cacheFileUrl(for: key)
        try? cache.write(to: fileUrl)
    }
    
    private func cacheFileUrl(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key.md5)
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }
    
    func cache(for key: String, completion: @escaping (Data?) -> Void) {
        ioQueue.async {
            let data = cache(for: key)
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    func set(_ cache: Data, for key: String, completion: @escaping () -> Void) {
        ioQueue.async {
            set(cache, for: key)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
