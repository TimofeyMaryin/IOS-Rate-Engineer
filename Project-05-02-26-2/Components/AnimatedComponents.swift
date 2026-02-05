//
//  AnimatedComponents.swift
//  Hourly Rate Engineer
//
//  Professional animated UI components with iOS 18+ features
//  Includes spring animations, SF Symbols effects, and accessibility
//

import SwiftUI

// MARK: - Animated Progress Ring (Enhanced)
struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: [Color]
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = -90
    
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: [Color] = [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle gradient
            Circle()
                .stroke(
                    AppTheme.Colors.divider.opacity(0.5),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress circle with animated gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient + [gradient.first ?? .blue]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))
            
            // Glow effect
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient.first ?? .blue,
                    style: StrokeStyle(lineWidth: lineWidth * 2, lineCap: .round)
                )
                .blur(radius: lineWidth)
                .opacity(0.3)
                .rotationEffect(.degrees(rotation))
            
            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.smooth) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(AppTheme.Animation.smooth) {
                animatedProgress = newValue
            }
        }
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
    }
}

// MARK: - Modern Donut Chart
struct DonutChartView: View {
    let segments: [DonutSegment]
    let innerRadiusRatio: CGFloat
    let showLabels: Bool
    
    @State private var animatedSegments: [DonutSegment] = []
    @State private var selectedSegment: UUID?
    
    struct DonutSegment: Identifiable, Equatable {
        let id = UUID()
        let value: Double
        let color: Color
        let label: String
        
        static func == (lhs: DonutSegment, rhs: DonutSegment) -> Bool {
            lhs.value == rhs.value && lhs.label == rhs.label
        }
    }
    
    init(segments: [DonutSegment], innerRadiusRatio: CGFloat = 0.65, showLabels: Bool = false) {
        self.segments = segments
        self.innerRadiusRatio = innerRadiusRatio
        self.showLabels = showLabels
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let outerRadius = size / 2
            let innerRadius = outerRadius * innerRadiusRatio
            
            ZStack {
                // Segments
                ForEach(Array(animatedSegments.enumerated()), id: \.element.id) { index, segment in
                    DonutSlice(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        innerRadius: innerRadius,
                        outerRadius: outerRadius
                    )
                    .fill(segment.color.gradient)
                    .shadow(color: segment.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    .scaleEffect(selectedSegment == segment.id ? 1.05 : 1)
                    .onTapGesture {
                        withAnimation(AppTheme.Animation.bouncy) {
                            selectedSegment = selectedSegment == segment.id ? nil : segment.id
                        }
                        AppTheme.Haptics.selection()
                    }
                }
                
                // Center content
                if showLabels, let selected = selectedSegment,
                   let segment = animatedSegments.first(where: { $0.id == selected }) {
                    VStack(spacing: 4) {
                        Text(segment.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.graphiteLight)
                        Text("\(Int((segment.value / total) * 100))%")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(segment.color)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.2)) {
                animatedSegments = segments
            }
        }
        .onChange(of: segments) { _, newValue in
            withAnimation(AppTheme.Animation.smooth) {
                animatedSegments = newValue
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chart with \(segments.count) segments")
    }
    
    private var total: Double {
        animatedSegments.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let precedingTotal = animatedSegments.prefix(index).reduce(0) { $0 + $1.value }
        return .degrees(360 * (precedingTotal / max(total, 1)) - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let includingTotal = animatedSegments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return .degrees(360 * (includingTotal / max(total, 1)) - 90)
    }
}

struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            // Animation support for smooth transitions
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Animated Counter (Enhanced)
struct AnimatedCounter: View {
    let value: Double
    let format: String
    let prefix: String
    let font: Font
    let color: Color
    
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        format: String = "%.2f",
        prefix: String = "",
        font: Font = AppTheme.Typography.monoLarge,
        color: Color = AppTheme.Colors.graphite
    ) {
        self.value = value
        self.format = format
        self.prefix = prefix
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text("\(prefix)\(String(format: format, displayValue))")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                withAnimation(AppTheme.Animation.smooth) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(AppTheme.Animation.smooth) {
                    displayValue = newValue
                }
            }
            .accessibilityLabel("\(prefix)\(String(format: format, value))")
    }
}

// MARK: - Pulse Button (Enhanced with SF Symbol Animation)
struct PulseButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPulsing = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button {
            AppTheme.Haptics.medium()
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                        .symbolEffect(.bounce, value: isPulsing)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                ZStack {
                    // Base
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Pulse effect
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(AppTheme.Colors.primary)
                        .scaleEffect(isPulsing ? 1.02 : 1)
                        .opacity(isPulsing ? 0 : 0.3)
                }
            }
            .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Progress Bar (Enhanced with Gradient)
struct AnimatedProgressBar: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundGradient: [Color]
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 10,
        backgroundColor: Color = AppTheme.Colors.divider.opacity(0.3),
        foregroundGradient: [Color] = [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundGradient = foregroundGradient
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(backgroundColor)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: foregroundGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geometry.size.width * animatedProgress))
                
                // Shine effect
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(height, geometry.size.width * animatedProgress))
                    .frame(height: height / 2)
                    .offset(y: -height / 4)
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(AppTheme.Animation.smooth) {
                animatedProgress = newValue
            }
        }
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
    }
}

// MARK: - Shimmer Effect (Enhanced)
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    init(duration: Double = 1.5) {
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.5), location: 0.3),
                            .init(color: .white.opacity(0.8), location: 0.5),
                            .init(color: .white.opacity(0.5), location: 0.7),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + phase * geometry.size.width * 1.6)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Loading Indicator (Modern)
struct LoadingIndicator: View {
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var rotation: Double = 0
    
    init(size: CGFloat = 32, lineWidth: CGFloat = 3) {
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.3)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 0.8)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
            .accessibilityLabel("Loading")
    }
}

// MARK: - Step Indicator (Enhanced)
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let completedColor: Color
    let activeColor: Color
    let inactiveColor: Color
    
    init(
        currentStep: Int,
        totalSteps: Int,
        completedColor: Color = AppTheme.Colors.success,
        activeColor: Color = AppTheme.Colors.primary,
        inactiveColor: Color = AppTheme.Colors.divider
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.completedColor = completedColor
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Group {
                    if step < currentStep {
                        // Completed
                        Circle()
                            .fill(completedColor)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                    } else if step == currentStep {
                        // Active
                        Circle()
                            .fill(activeColor)
                            .overlay {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 4, height: 4)
                            }
                    } else {
                        // Inactive
                        Circle()
                            .fill(inactiveColor)
                    }
                }
                .frame(width: step == currentStep ? 12 : 8, height: step == currentStep ? 12 : 8)
                .animation(AppTheme.Animation.bouncy, value: currentStep)
            }
        }
        .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            AppTheme.Haptics.medium()
            action()
        } label: {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(AppTheme.Animation.bouncy, value: isPressed)
    }
}

// MARK: - Animated Checkmark
struct AnimatedCheckmark: View {
    let isChecked: Bool
    let size: CGFloat
    let color: Color
    
    init(isChecked: Bool, size: CGFloat = 24, color: Color = AppTheme.Colors.success) {
        self.isChecked = isChecked
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? color : AppTheme.Colors.divider)
                .frame(width: size, height: size)
            
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(AppTheme.Animation.bouncy, value: isChecked)
        .accessibilityLabel(isChecked ? "Checked" : "Unchecked")
    }
}

// MARK: - Scale Button Effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppTheme.Animation.instant, value: configuration.isPressed)
    }
}

// MARK: - Previews
#Preview("Progress Ring") {
    VStack(spacing: 30) {
        AnimatedProgressRing(progress: 0.75, showPercentage: true)
            .frame(width: 120, height: 120)
        
        AnimatedProgressBar(progress: 0.6)
            .frame(width: 200)
    }
    .padding()
}

#Preview("Donut Chart") {
    DonutChartView(
        segments: [
            .init(value: 50, color: AppTheme.Colors.chartBlue, label: "Income"),
            .init(value: 20, color: AppTheme.Colors.chartRed, label: "Taxes"),
            .init(value: 15, color: AppTheme.Colors.chartOrange, label: "Costs"),
            .init(value: 10, color: AppTheme.Colors.chartPurple, label: "Equipment"),
            .init(value: 5, color: AppTheme.Colors.chartGreen, label: "Safety")
        ],
        showLabels: true
    )
    .frame(width: 200, height: 200)
    .padding()
}

#Preview("Step Indicator") {
    VStack(spacing: 20) {
        StepIndicator(currentStep: 0, totalSteps: 5)
        StepIndicator(currentStep: 2, totalSteps: 5)
        StepIndicator(currentStep: 4, totalSteps: 5)
    }
    .padding()
}

#Preview("Loading") {
    VStack(spacing: 30) {
        LoadingIndicator()
        
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.Colors.divider)
            .frame(width: 200, height: 40)
            .shimmer()
    }
    .padding()
}
