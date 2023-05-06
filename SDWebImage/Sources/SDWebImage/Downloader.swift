import Foundation

class Downloader {
    private let downloadQueue = DispatchQueue(label: "com.hackemist.SDWebImageDownloader", attributes: .concurrent)
    
    private var handlerDict = [URL: [(Data?) -> Void]]()
    
    func downloadImage(wirh url: URL, completion: @escaping (Data?) -> Void) {
        // 如果已经对url发起了请求，不需要再次请求，只需添加一个回调即可
        if handlerDict[url] == nil {
            handlerDict[url, default: []].append(completion)
            
            var request = URLRequest(url: url)
            request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            downloadQueue.async {
                URLSession.shared.dataTask(with: request) { data, _, _ in
                    DispatchQueue.main.async {
                        self.handlerDict[url]?.forEach({ completion in
                            completion(data)
                        })
                        self.handlerDict[url] = nil
                    }
                }.resume()
            }
        } else {
            handlerDict[url]?.append(completion)
        }
    }
}
