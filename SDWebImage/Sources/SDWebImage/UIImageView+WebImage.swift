import UIKit

public extension UIImageView {
    func sd_setImage(with url: URL?, placeholderImage: UIImage? = nil) {
        self.image = placeholderImage
        
        ImageManager.shared.loadImage(with: url) { image in
            self.image = image
        }
    }
}
