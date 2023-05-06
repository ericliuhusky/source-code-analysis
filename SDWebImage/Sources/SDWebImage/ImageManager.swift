import Foundation
import UIKit

public class ImageManager {
    public static let shared = ImageManager()
    
    private let memoryCache = MemoryCache()
    private let diskCache = DiskCache()
    
    private let downLoader = Downloader()
    
    func loadImage(with url: URL?, completion: @escaping (UIImage) -> Void) {
        guard let url else { return }
        let key = url.absoluteString
        
        if let image = memoryCache.cache(for: key) {
            completion(image)
            return
        }
        
        diskCache.cache(for: key) { data in
            if let data, let image = UIImage(data: data)?.preparingForDisplay {
                self.memoryCache.set(image, for: key)
                completion(image)
                return
            }
            
            self.downLoader.downloadImage(wirh: url) { data in
                if let data, let image = UIImage(data: data)?.preparingForDisplay {
                    self.memoryCache.set(image, for: key)
                    self.diskCache.set(data, for: key) {
                        completion(image)
                    }
                }
            }
        }
    }
    
    public func clear() {
        memoryCache.clear()
        diskCache.clear()
    }
}
