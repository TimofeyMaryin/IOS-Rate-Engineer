//
//  ContentRenderer.swift
//  Hourly Rate Engineer
//

import SwiftUI
import WebKit

/// A bridge component that renders web-based content within the native interface
/// Utilizes WKWebView for modern web standards compliance
struct ContentRenderer: UIViewRepresentable {
    
    /// The resource identifier to be rendered
    private let resourceIdentifier: String
    
    /// Initializes the renderer with a target resource
    /// - Parameter resource: URL string pointing to the content source
    init(resource: String) {
        self.resourceIdentifier = resource
    }
    
    // MARK: - UIViewRepresentable Conformance
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let renderer = WKWebView(frame: .zero, configuration: configuration)
        renderer.navigationDelegate = context.coordinator
        renderer.allowsBackForwardNavigationGestures = true
        renderer.scrollView.bounces = true
        renderer.scrollView.showsVerticalScrollIndicator = true
        
        return renderer
    }
    
    func updateUIView(_ renderer: WKWebView, context: Context) {
        guard let sanitizedResource = prepareResourceLocator(resourceIdentifier) else {
            return
        }
        
        let targetLocation = URL(string: sanitizedResource)
        
        guard let destination = targetLocation, renderer.url != destination else {
            return
        }
        
        let contentRequest = URLRequest(
            url: destination,
            cachePolicy: .reloadRevalidatingCacheData,
            timeoutInterval: 30
        )
        
        renderer.load(contentRequest)
    }
    
    func makeCoordinator() -> NavigationHandler {
        NavigationHandler()
    }
    
    // MARK: - Private Helpers
    
    private func prepareResourceLocator(_ raw: String) -> String? {
        raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

// MARK: - Navigation Handler

extension ContentRenderer {
    
    /// Handles navigation events from the web renderer
    final class NavigationHandler: NSObject, WKNavigationDelegate {
        
        private var isNavigating = false
        
        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            isNavigating = true
        }
        
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            isNavigating = false
        }
        
        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            isNavigating = false
            #if DEBUG
            print("[ContentRenderer] Navigation failed: \(error.localizedDescription)")
            #endif
        }
        
        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            isNavigating = false
        }
    }
}

// MARK: - Convenience Initializer

extension ContentRenderer {
    
    /// Creates a renderer from an optional URL, returning nil if invalid
    static func create(from urlString: String?) -> ContentRenderer? {
        guard let str = urlString, URL(string: str) != nil else {
            return nil
        }
        return ContentRenderer(resource: str)
    }
}
