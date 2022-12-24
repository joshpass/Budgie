//
//  WebView.swift
//  Budgie
//
//  Created by Josh Pasricha on 24/12/22.
//

import Foundation

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var html: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
