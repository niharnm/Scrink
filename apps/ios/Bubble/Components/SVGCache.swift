import Foundation
import UIKit
import WebKit

@MainActor @Observable
final class SVGCache {
    static let shared = SVGCache()

    private(set) var images: [String: UIImage] = [:]
    private var svgStrings: [String: String] = [:]

    private init() {}

    func preload(svgNames: [String], size: CGSize = CGSize(width: 200, height: 200)) {
        for name in svgNames {
            guard images[name] == nil else { continue }
            guard let svgString = loadSVGString(name) else { continue }

            Task {
                if let image = await renderToImage(svgString: svgString, size: size) {
                    images[name] = image
                }
            }
        }
    }

    func loadSVGString(_ name: String) -> String? {
        if let cached = svgStrings[name] { return cached }
        guard let path = Bundle.main.path(forResource: name, ofType: "svg"),
              let svgString = try? String(contentsOfFile: path) else { return nil }
        svgStrings[name] = svgString
        return svgString
    }

    private func renderToImage(svgString: String, size: CGSize) async -> UIImage? {
        let webView = WKWebView(frame: CGRect(origin: .zero, size: size))
        webView.backgroundColor = .clear
        webView.isOpaque = false

        let html = Self.buildHTML(svgString: svgString)
        let awaiter = NavigationAwaiter()
        webView.navigationDelegate = awaiter
        webView.loadHTMLString(html, baseURL: nil)

        await awaiter.waitForLoad()

        let config = WKSnapshotConfiguration()
        config.afterScreenUpdates = true
        return try? await webView.takeSnapshot(configuration: config)
    }

    static func buildHTML(svgString: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
                svg { width: 100%; height: 100%; }
            </style>
        </head>
        <body>\(svgString)</body>
        </html>
        """
    }
}

@MainActor
private final class NavigationAwaiter: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Never>?

    func waitForLoad() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}
