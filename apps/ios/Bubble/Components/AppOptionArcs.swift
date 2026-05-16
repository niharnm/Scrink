import SwiftUI

struct AppOptionArcs: View {
    let options: [AppOption]
    let radius: CGFloat
    let lineWidth: CGFloat
    var onToggleOption: ((String) -> Void)?
    
    init(options: [AppOption], radius: CGFloat = 140, lineWidth: CGFloat = 3, onToggleOption: ((String) -> Void)? = nil) {
        self.options = options
        self.radius = radius
        self.lineWidth = lineWidth
        self.onToggleOption = onToggleOption
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let arcInfo = arcInfoFor(index: index, total: options.count)
                    
                    // Discrete arc segment - tappable
                    ArcShape(
                        startAngle: arcInfo.startAngle,
                        endAngle: arcInfo.endAngle,
                        radius: radius
                    )
                    .stroke(
                        option.isSelected ? Color.white : Color.white.opacity(0.3),
                        lineWidth: lineWidth
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    .contentShape(ArcTapShape(
                        startAngle: arcInfo.startAngle,
                        endAngle: arcInfo.endAngle,
                        radius: radius
                    ))
                    .onTapGesture {
                        onToggleOption?(option.id)
                    }
                    
                    // Floating text label near the arc with bobbing animation
                    let labelAngle = (arcInfo.startAngle + arcInfo.endAngle) / 2
                    let labelRadius = radius + 40 // Position text slightly outside the arc
                    let baseLabelX = center.x + labelRadius * cos(labelAngle)
                    let baseLabelY = center.y + labelRadius * sin(labelAngle)
                    
                    FloatingLabel(
                        text: option.label,
                        baseX: baseLabelX,
                        baseY: baseLabelY,
                        index: index
                    )
                }
            }
        }
    }
    
    private func arcInfoFor(index: Int, total: Int) -> (startAngle: CGFloat, endAngle: CGFloat) {
        let topAngle: CGFloat = -.pi / 2 // Top of circle (midline of screen)
        let gapSize: CGFloat = 0.15 // Gap between arcs (in radians) - more visible
        let arcSize: CGFloat = (2 * .pi - (CGFloat(total) * gapSize)) / CGFloat(total) // Equal size for all arcs
        
        // Center the first arc at the top (midline)
        // First arc midpoint is at topAngle, so it starts at topAngle - arcSize/2
        let firstArcStart = topAngle - arcSize / 2
        
        // Calculate start angle for this arc index
        let start = firstArcStart + (CGFloat(index) * (arcSize + gapSize))
        let end = start + arcSize
        
        return (startAngle: start, endAngle: end)
    }
}

struct FloatingLabel: View {
    let text: String
    let baseX: CGFloat
    let baseY: CGFloat
    let index: Int
    
    @State private var bobOffset: CGFloat = 0
    
    var body: some View {
        Text(text)
            .font(BubbleFonts.coolvetica(size: 14))
            .foregroundStyle(.white)
            // Text always right side up (no rotation)
            .position(x: baseX, y: baseY - bobOffset) // Bob upward
            .onAppear {
                // Start bobbing animation with unique timing for each label
                let duration = 1.5 + Double(index) * 0.2
                let delay = Double(index) * 0.15
                
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    bobOffset = 8
                }
            }
    }
}

struct ArcShape: Shape {
    let startAngle: CGFloat
    let endAngle: CGFloat
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(radians: Double(startAngle)),
            endAngle: Angle(radians: Double(endAngle)),
            clockwise: false
        )
        
        return path
    }
}

// Shape for tap detection on arcs
struct ArcTapShape: Shape {
    let startAngle: CGFloat
    let endAngle: CGFloat
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Create a wider tap area (arc with thickness)
        let tapRadius = radius
        let tapThickness: CGFloat = 30 // Tap area extends 30 points on each side
        
        // Outer arc
        path.addArc(
            center: center,
            radius: tapRadius + tapThickness,
            startAngle: Angle(radians: Double(startAngle)),
            endAngle: Angle(radians: Double(endAngle)),
            clockwise: false
        )
        
        // Connect to inner arc
        let innerEndX = center.x + (tapRadius - tapThickness) * cos(endAngle)
        let innerEndY = center.y + (tapRadius - tapThickness) * sin(endAngle)
        path.addLine(to: CGPoint(x: innerEndX, y: innerEndY))
        
        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: tapRadius - tapThickness,
            startAngle: Angle(radians: Double(endAngle)),
            endAngle: Angle(radians: Double(startAngle)),
            clockwise: true
        )
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        AppOptionArcs(
            options: [
                AppOption(id: "reels", label: "short video", isSelected: true)
            ],
            radius: 140
        )
        .frame(width: 300, height: 300)
    }
}
