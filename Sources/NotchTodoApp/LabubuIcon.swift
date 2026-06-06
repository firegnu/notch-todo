import AppKit
import SwiftUI

enum LabubuIcon {
    static let image: NSImage? = {
        guard let url = Bundle.main.url(
            forResource: "labubu-pixel",
            withExtension: "png"
        ) else {
            return nil
        }

        let image = NSImage(contentsOf: url)
        image?.isTemplate = false
        return image
    }()
}

struct LabubuIconView: View {
    let size: CGFloat

    var body: some View {
        if let image = LabubuIcon.image {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
        }
    }
}
