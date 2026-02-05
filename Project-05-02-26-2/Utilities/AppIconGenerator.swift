//
//  AppIconGenerator.swift
//  Hourly Rate Engineer
//
//  Generates app icon programmatically
//

import SwiftUI
import UIKit

// MARK: - App Icon View (for Preview and Generation)
struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "007AFF"),
                    Color(hex: "0A84FF"),
                    Color(hex: "5856D6")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let gridSize = size / 8
                    for i in 0..<9 {
                        let x = CGFloat(i) * gridSize
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size))
                    }
                    for i in 0..<9 {
                        let y = CGFloat(i) * gridSize
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
            
            // Main icon content
            VStack(spacing: size * 0.02) {
                // Clock with checkmark
                ZStack {
                    // Clock circle
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: size * 0.55, height: size * 0.55)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.48, height: size * 0.48)
                    
                    // Clock hands
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "4D4D4D"))
                            .frame(width: size * 0.02, height: size * 0.12)
                            .offset(y: -size * 0.06)
                    }
                    .rotationEffect(.degrees(-30))
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "007AFF"))
                            .frame(width: size * 0.025, height: size * 0.16)
                            .offset(y: -size * 0.08)
                    }
                    .rotationEffect(.degrees(60))
                    
                    // Center dot
                    Circle()
                        .fill(Color(hex: "007AFF"))
                        .frame(width: size * 0.05, height: size * 0.05)
                    
                    // Checkmark badge
                    ZStack {
                        Circle()
                            .fill(Color(hex: "34C759"))
                            .frame(width: size * 0.18, height: size * 0.18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.08, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: size * 0.15, y: size * 0.15)
                }
                
                // Dollar sign indicator
                HStack(spacing: size * 0.02) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: size * 0.02)
                            .fill(Color.white.opacity(0.3 + Double(i) * 0.2))
                            .frame(width: size * 0.08, height: size * 0.03)
                    }
                }
                .padding(.top, size * 0.02)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

// MARK: - Alternative Simple Icon
struct AppIconSimpleView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "007AFF"),
                    Color(hex: "0052CC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Icon
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(.white, Color(hex: "34C759"))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

// MARK: - Icon Generator
@MainActor
class AppIconGenerator {
    
    static func generateIcon(size: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: AppIconSimpleView(size: size))
        renderer.scale = 1.0
        return renderer.uiImage
    }
    
    static func generateAllIcons() -> [String: UIImage] {
        var icons: [String: UIImage] = [:]
        
        let sizes: [(name: String, size: CGFloat)] = [
            ("AppIcon-1024", 1024),
            ("AppIcon-Mac-16", 16),
            ("AppIcon-Mac-32", 32),
            ("AppIcon-Mac-64", 64),
            ("AppIcon-Mac-128", 128),
            ("AppIcon-Mac-256", 256),
            ("AppIcon-Mac-512", 512),
            ("AppIcon-Mac-1024", 1024)
        ]
        
        for (name, size) in sizes {
            if let image = generateIcon(size: size) {
                icons[name] = image
            }
        }
        
        return icons
    }
    
    static func saveIconsToDocuments() {
        let icons = generateAllIcons()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for (name, image) in icons {
            if let data = image.pngData() {
                let fileURL = documentsPath.appendingPathComponent("\(name).png")
                try? data.write(to: fileURL)
                print("Saved: \(fileURL.path)")
            }
        }
    }
}

// MARK: - Previews
#Preview("App Icon 1024") {
    AppIconView(size: 1024)
        .frame(width: 300, height: 300)
        .scaleEffect(0.3)
}

#Preview("App Icon Simple") {
    AppIconSimpleView(size: 512)
        .frame(width: 256, height: 256)
        .scaleEffect(0.5)
}

#Preview("Icon Gallery") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AppIconSimpleView(size: 120)
            AppIconSimpleView(size: 80)
            AppIconSimpleView(size: 60)
        }
        
        HStack(spacing: 20) {
            AppIconView(size: 120)
            AppIconView(size: 80)
            AppIconView(size: 60)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
