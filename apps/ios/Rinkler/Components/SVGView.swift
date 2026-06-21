import SwiftUI
import WebKit

struct SVGView: View {
    let svgName: String

    var body: some View {
        if let image = SVGCache.shared.images[svgName] {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            SVGWebView(svgName: svgName)
        }
    }
}

/// Fallback WKWebView-based renderer used when a pre-rendered image isn't cached yet.
private struct SVGWebView: UIViewRepresentable {
    let svgName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false

        if let svgString = SVGCache.shared.loadSVGString(svgName) {
            let html = SVGCache.buildHTML(svgString: svgString)
            webView.loadHTMLString(html, baseURL: nil)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
