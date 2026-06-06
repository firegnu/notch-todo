import AppKit
import SwiftUI

enum LabubuAnimation {
    enum Frame: Equatable, Sendable {
        case idle
        case blink
        case earDip
        case recover
    }

    static let frames: [Frame] = [.idle, .blink, .earDip, .recover]
    static let idleDuration = Duration.milliseconds(4_600)
    static let frameDuration = Duration.milliseconds(120)
}

enum LabubuIcon {
    static let image = loadImage(named: "labubu-pixel")
    static let blinkImage = loadImage(named: "labubu-pixel-blink")

    private static func loadImage(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "png"
        ) else {
            return nil
        }

        let image = NSImage(contentsOf: url)
        image?.isTemplate = false
        return image
    }
}

struct LabubuIconView: View {
    let size: CGFloat
    var celebrationTrigger = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame: LabubuAnimation.Frame = .idle
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let image = currentImage {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
                    .offset(y: frame == .earDip ? 1 : 0)
            }
        }
        .task {
            guard !reduceMotion else { return }
            startIdleLoop()
        }
        .onChange(of: celebrationTrigger) { _, isComplete in
            guard isComplete, !reduceMotion else { return }
            playCelebration()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private var currentImage: NSImage? {
        frame == .blink ? LabubuIcon.blinkImage : LabubuIcon.image
    }

    private func startIdleLoop() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                frame = .idle
                try? await Task.sleep(for: LabubuAnimation.idleDuration)
                guard !Task.isCancelled else { return }

                for nextFrame in LabubuAnimation.frames.dropFirst() {
                    frame = nextFrame
                    try? await Task.sleep(for: LabubuAnimation.frameDuration)
                    guard !Task.isCancelled else { return }
                }
            }
        }
    }

    private func playCelebration() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            frame = .earDip
            try? await Task.sleep(for: LabubuAnimation.frameDuration)
            guard !Task.isCancelled else { return }
            frame = .recover
            try? await Task.sleep(for: LabubuAnimation.frameDuration)
            guard !Task.isCancelled else { return }
            startIdleLoop()
        }
    }
}
