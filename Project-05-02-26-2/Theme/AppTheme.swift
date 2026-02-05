//
//  AppTheme.swift
//  Hourly Rate Engineer
//
//  Professional design system with iOS 18+ features
//  Supports Dynamic Type, Dark Mode, and Accessibility
//

import SwiftUI

// MARK: - App Theme
enum AppTheme {
    
    // MARK: - Colors (Adaptive Light/Dark Mode)
    enum Colors {
        // Primary palette - using semantic colors for automatic dark mode
        static let primary = Color.accentColor
        static let primaryAccent = Color(light: Color(hex: "0A84FF"), dark: Color(hex: "64D2FF"))
        static let secondary = Color(light: Color(hex: "5856D6"), dark: Color(hex: "BF5AF2"))
        
        // Neutrals - adaptive
        static let graphite = Color(light: Color(hex: "1C1C1E"), dark: Color(hex: "F2F2F7"))
        static let graphiteLight = Color(light: Color(hex: "8E8E93"), dark: Color(hex: "98989D"))
        static let background = Color(light: Color(hex: "F2F2F7"), dark: Color(hex: "000000"))
        static let secondaryBackground = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1C1C1E"))
        static let tertiaryBackground = Color(light: Color(hex: "F9F9FB"), dark: Color(hex: "2C2C2E"))
        static let cardBackground = Color(light: .white, dark: Color(hex: "1C1C1E"))
        static let divider = Color(light: Color(hex: "E5E5EA"), dark: Color(hex: "38383A"))
        
        // Semantic colors
        static let success = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
        static let warning = Color(light: Color(hex: "FF9500"), dark: Color(hex: "FF9F0A"))
        static let error = Color(light: Color(hex: "FF3B30"), dark: Color(hex: "FF453A"))
        
        // Chart colors - vibrant for both modes
        static let chartBlue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
        static let chartRed = Color(light: Color(hex: "FF3B30"), dark: Color(hex: "FF453A"))
        static let chartOrange = Color(light: Color(hex: "FF9500"), dark: Color(hex: "FF9F0A"))
        static let chartPurple = Color(light: Color(hex: "AF52DE"), dark: Color(hex: "BF5AF2"))
        static let chartGreen = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
        static let chartTeal = Color(light: Color(hex: "5AC8FA"), dark: Color(hex: "64D2FF"))
        static let chartPink = Color(light: Color(hex: "FF2D55"), dark: Color(hex: "FF375F"))
        static let chartIndigo = Color(light: Color(hex: "5856D6"), dark: Color(hex: "5E5CE6"))
        
        // Gradient colors for MeshGradient
        static let meshColors: [Color] = [
            Color(hex: "007AFF").opacity(0.3),
            Color(hex: "5856D6").opacity(0.2),
            Color(hex: "AF52DE").opacity(0.15),
            Color(hex: "5AC8FA").opacity(0.25),
            Color(hex: "34C759").opacity(0.1),
            Color(hex: "007AFF").opacity(0.2),
            Color(hex: "5856D6").opacity(0.15),
            Color(hex: "0A84FF").opacity(0.2),
            Color(hex: "64D2FF").opacity(0.1)
        ]
    }
    
    // MARK: - Typography (Dynamic Type Support)
    enum Typography {
        // Using system fonts with Dynamic Type
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        
        // Monospaced for numbers - with Dynamic Type
        static let monoLarge = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let monoMedium = Font.system(.title, design: .rounded).weight(.semibold)
        static let monoSmall = Font.system(.title3, design: .rounded).weight(.medium)
        
        // Fixed sizes for specific UI elements
        static func fixed(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            Font.system(size: size, weight: weight, design: .rounded)
        }
    }
    
    // MARK: - Spacing (Responsive)
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xlarge: CGFloat = 28
        static let xxlarge: CGFloat = 36
        static let continuous: CGFloat = 999 // For pill shapes
    }
    
    // MARK: - Shadows (Adaptive)
    enum Shadows {
        static let subtle = ShadowStyle(color: Color.black.opacity(0.04), radius: 2, y: 1)
        static let small = ShadowStyle(color: Color.black.opacity(0.06), radius: 4, y: 2)
        static let medium = ShadowStyle(color: Color.black.opacity(0.08), radius: 10, y: 4)
        static let large = ShadowStyle(color: Color.black.opacity(0.12), radius: 20, y: 8)
        static let glow = ShadowStyle(color: Colors.primary.opacity(0.3), radius: 20, y: 0)
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation (iOS 18+ Spring Animations)
    enum Animation {
        static let instant = SwiftUI.Animation.spring(duration: 0.15, bounce: 0.1)
        static let quick = SwiftUI.Animation.spring(duration: 0.25, bounce: 0.15)
        static let standard = SwiftUI.Animation.spring(duration: 0.35, bounce: 0.2)
        static let smooth = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.15)
        static let gentle = SwiftUI.Animation.spring(duration: 0.6, bounce: 0.1)
        static let bouncy = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.35)
        static let snappy = SwiftUI.Animation.snappy(duration: 0.3)
        
        // Interactive animations
        static let interactiveSpring = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Haptics
    enum Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        static func heavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        
        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        static func warning() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        static func error() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Color Extension (Adaptive Colors)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Create adaptive color for light/dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Glass Card Style (iOS 18+ Material)
struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let intensity: Double
    
    init(intensity: Double = 0.8) {
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(intensity))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                           radius: 12, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Modern Card Style
struct ModernCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let padding: CGFloat
    
    init(padding: CGFloat = AppTheme.Spacing.lg) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? .clear : Color.black.opacity(0.06),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .strokeBorder(
                        AppTheme.Colors.divider.opacity(colorScheme == .dark ? 0.3 : 0.5),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Primary Button Style (Enhanced)
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(
                            isEnabled
                                ? LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [AppTheme.Colors.graphiteLight.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                    
                    // Shine overlay
                    if isEnabled && !configuration.isPressed {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
            }
            .shadow(
                color: isEnabled ? AppTheme.Colors.primary.opacity(0.4) : .clear,
                radius: configuration.isPressed ? 4 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    AppTheme.Haptics.light()
                }
            }
    }
}

// MARK: - Secondary Button Style (Enhanced)
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(AppTheme.Colors.primary.opacity(configuration.isPressed ? 0.15 : 0.1))
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .strokeBorder(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    AppTheme.Haptics.light()
                }
            }
    }
}

// MARK: - Tertiary Button Style
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.Colors.graphiteLight)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background {
                Capsule()
                    .fill(AppTheme.Colors.tertiaryBackground)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppTheme.Animation.instant, value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let background: Color
    
    init(size: CGFloat = 44, background: Color = AppTheme.Colors.tertiaryBackground) {
        self.size = size
        self.background = background
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(background)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(AppTheme.Animation.instant, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    AppTheme.Haptics.selection()
                }
            }
    }
}

// MARK: - Input Field Style (Enhanced)
struct InputFieldStyle: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(AppTheme.Colors.tertiaryBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .strokeBorder(
                        isFocused ? AppTheme.Colors.primary : AppTheme.Colors.divider.opacity(0.5),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .animation(AppTheme.Animation.quick, value: isFocused)
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(intensity: Double = 0.8) -> some View {
        modifier(GlassCardStyle(intensity: intensity))
    }
    
    func modernCard(padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        modifier(ModernCardStyle(padding: padding))
    }
    
    func inputFieldStyle(isFocused: FocusState<Bool>.Binding) -> some View {
        modifier(InputFieldStyle(isFocused: isFocused))
    }
    
    func shadowSubtle() -> some View {
        shadow(color: AppTheme.Shadows.subtle.color, radius: AppTheme.Shadows.subtle.radius, y: AppTheme.Shadows.subtle.y)
    }
    
    func shadowSmall() -> some View {
        shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, y: AppTheme.Shadows.small.y)
    }
    
    func shadowMedium() -> some View {
        shadow(color: AppTheme.Shadows.medium.color, radius: AppTheme.Shadows.medium.radius, y: AppTheme.Shadows.medium.y)
    }
    
    func shadowLarge() -> some View {
        shadow(color: AppTheme.Shadows.large.color, radius: AppTheme.Shadows.large.radius, y: AppTheme.Shadows.large.y)
    }
    
    func shadowGlow() -> some View {
        shadow(color: AppTheme.Shadows.glow.color, radius: AppTheme.Shadows.glow.radius, y: AppTheme.Shadows.glow.y)
    }
}

// MARK: - Mesh Gradient Background (iOS 18+)
struct MeshGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    let animate: Bool
    
    @State private var phase: CGFloat = 0
    
    init(animate: Bool = true) {
        self.animate = animate
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: !animate)) { timeline in
            let time = animate ? timeline.date.timeIntervalSinceReferenceDate : 0
            
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [Float(0.5 + 0.1 * sin(time * 0.5)), Float(0.5 + 0.1 * cos(time * 0.3))], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: colorScheme == .dark ? [
                    Color(hex: "0A84FF").opacity(0.15),
                    Color(hex: "5E5CE6").opacity(0.1),
                    Color(hex: "BF5AF2").opacity(0.08),
                    Color(hex: "64D2FF").opacity(0.12),
                    Color(hex: "30D158").opacity(0.05),
                    Color(hex: "0A84FF").opacity(0.1),
                    Color(hex: "5E5CE6").opacity(0.08),
                    Color(hex: "0A84FF").opacity(0.1),
                    Color(hex: "64D2FF").opacity(0.05)
                ] : AppTheme.Colors.meshColors
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Animated Gradient Border
struct AnimatedGradientBorder: View {
    @State private var rotation: Double = 0
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    
    init(cornerRadius: CGFloat = AppTheme.CornerRadius.large, lineWidth: CGFloat = 2) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    colors: [
                        AppTheme.Colors.chartBlue,
                        AppTheme.Colors.chartPurple,
                        AppTheme.Colors.chartPink,
                        AppTheme.Colors.chartOrange,
                        AppTheme.Colors.chartBlue
                    ],
                    center: .center,
                    angle: .degrees(rotation)
                ),
                lineWidth: lineWidth
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Disclaimer Text (Enhanced)
struct DisclaimerText: View {
    var body: some View {
        Text("This is a private personal calculator for freelance rate estimation. Not financial advice or professional consulting.")
            .font(.caption2)
            .foregroundStyle(AppTheme.Colors.graphiteLight)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .accessibilityLabel("Disclaimer: This is a private personal calculator for freelance rate estimation. Not financial advice or professional consulting.")
    }
}

// MARK: - Section Header (Enhanced)
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Info Tip (Enhanced)
struct InfoTip: View {
    let text: String
    let icon: String
    let color: Color
    
    init(_ text: String, icon: String = "lightbulb.fill", color: Color = AppTheme.Colors.warning) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.graphiteLight)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(color.opacity(0.1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(text)")
    }
}

// MARK: - Currency Formatter
struct CurrencyFormatter {
    static func format(_ value: Double, currency: String, showDecimals: Bool = true) -> String {
        let symbol = CurrencyInfo.symbol(for: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = showDecimals ? 2 : 0
        formatter.maximumFractionDigits = showDecimals ? 2 : 0
        formatter.groupingSeparator = ","
        
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(symbol)\(formatted)"
    }
    
    static func formatCompact(_ value: Double, currency: String) -> String {
        let symbol = CurrencyInfo.symbol(for: currency)
        if value >= 1000000 {
            return "\(symbol)\(String(format: "%.1fM", value / 1000000))"
        } else if value >= 1000 {
            return "\(symbol)\(String(format: "%.1fK", value / 1000))"
        } else {
            return "\(symbol)\(String(format: "%.0f", value))"
        }
    }
}

// MARK: - Previews
#Preview("Colors") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ColorSwatch(color: AppTheme.Colors.primary, name: "Primary")
            ColorSwatch(color: AppTheme.Colors.primaryAccent, name: "Accent")
            ColorSwatch(color: AppTheme.Colors.secondary, name: "Secondary")
            ColorSwatch(color: AppTheme.Colors.success, name: "Success")
            ColorSwatch(color: AppTheme.Colors.warning, name: "Warning")
            ColorSwatch(color: AppTheme.Colors.error, name: "Error")
        }
        .padding()
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 60)
            Text(name)
                .font(.caption2)
        }
    }
}

#Preview("Buttons") {
    VStack(spacing: 20) {
        Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())
        
        Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
        
        Button("Tertiary Button") {}
            .buttonStyle(TertiaryButtonStyle())
    }
    .padding()
}

#Preview("Cards") {
    VStack(spacing: 20) {
        Text("Glass Card")
            .padding()
            .frame(maxWidth: .infinity)
            .glassCard()
        
        Text("Modern Card")
            .modernCard()
    }
    .padding()
    .background(MeshGradientBackground())
}
