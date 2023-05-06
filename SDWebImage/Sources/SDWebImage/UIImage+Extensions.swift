import UIKit

extension UIImage {
    func image(_ size: CGSize, _ opaque: Bool = false, _ scale: CGFloat = 1, actions: (CGContext) -> Void) -> UIImage {
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = opaque
            let render = UIGraphicsImageRenderer(size: size, format: format)
            return render.image { context in
                actions(context.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
            defer {
                UIGraphicsEndImageContext()
            }
            let context = UIGraphicsGetCurrentContext()!
            actions(context)
            return UIGraphicsGetImageFromCurrentImageContext()!
        }
    }
    
    var preparingForDisplay: UIImage {
        if #available(iOS 15.0, *) {
            return preparingForDisplay()!
        } else {
            return image(size, isOpaque) { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    var isOpaque: Bool {
        let alphaInfo = cgImage!.alphaInfo
        return alphaInfo == .none || alphaInfo == .noneSkipLast || alphaInfo == .noneSkipFirst
    }
    
    var cost: Int {
        cgImage!.bytesPerRow * cgImage!.height
    }
}
