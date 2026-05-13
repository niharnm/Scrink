import SwiftUI

struct SkyBackgroundView: View {
    @State private var offset: CGFloat = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image - unrotated, fills entire device from edge to edge
                if let path = Bundle.main.path(forResource: "background", ofType: "png"),
                   let backgroundImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .zIndex(0)
                } else {
                    // Fallback to solid blue if image not found
                    Color(red: 0.227, green: 0.553, blue: 0.871)
                        .zIndex(0)
                }
                
                // Moving cloud carousel - aligned to bottom of screen, on top of background
                VStack {
                    Spacer()
                    
                    // Try multiple methods to load the cloud image
                    let cloudImage: UIImage? = {
                        // Method 1: Standard bundle lookup
                        if let img = UIImage(named: "clouds_continous") {
                            return img
                        }
                        // Method 2: Using URL-based lookup
                        if let url = Bundle.main.url(forResource: "clouds_continous", withExtension: "png"),
                           let img = UIImage(contentsOfFile: url.path) {
                            return img
                        }
                        // Method 3: Direct path lookup (original method)
                        if let path = Bundle.main.path(forResource: "clouds_continous", ofType: "png"),
                           let img = UIImage(contentsOfFile: path) {
                            return img
                        }
                        return nil
                    }()
                    
                    if let cloudImage = cloudImage {
                        let screenWidth = geometry.size.width
                        // Get the actual image dimensions
                        let imageSize = cloudImage.size
                        let imageNaturalWidth = imageSize.width
                        let imageNaturalHeight = imageSize.height
                        
                        // Scale the image based on a target display height to maintain aspect ratio
                        // This ensures the full image width is properly scaled and visible
                        let targetDisplayHeight = geometry.size.height * 0.3  // Use 30% of screen height
                        let scaleFactor = targetDisplayHeight / imageNaturalHeight
                        let scaledWidth = imageNaturalWidth * scaleFactor
                        
                        // Overlap amount to prevent vertical bar (negative spacing creates overlap)
                        let overlap: CGFloat = 5
                        
                        // Calculate the actual spacing between image starts
                        // With negative spacing, each image starts at: previousImageStart + scaledWidth - overlap
                        let actualSpacing = scaledWidth - overlap
                        
                        // Use actualSpacing for cycle width to match where images actually repeat
                        // This prevents jumping by ensuring the wrap aligns with the image pattern
                        // Note: Using actualSpacing instead of scaledWidth for visual correctness
                        let cycleWidth = actualSpacing
                        
                        HStack(spacing: -overlap) {
                            // Multiple copies for seamless infinite scroll
                            // Need enough copies so wrap is invisible
                            ForEach(0..<6, id: \.self) { _ in
                                Image(uiImage: cloudImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: scaledWidth)
                            }
                        }
                        .offset(x: offset)
                        .frame(width: screenWidth)
                        .clipped()
                        .onAppear {
                            // Debug: Print the dimensions to understand what we're working with
                            print("Image natural size: \(imageNaturalWidth) x \(imageNaturalHeight)")
                            print("Screen width: \(screenWidth)")
                            print("Target display height: \(targetDisplayHeight)")
                            print("Scale factor: \(scaleFactor)")
                            print("Scaled width (display): \(scaledWidth)")
                            print("Actual spacing between images: \(actualSpacing)")
                            print("Cycle width: \(cycleWidth)")
                            print("Cycle width in image widths: \(cycleWidth / scaledWidth)")
                            
                            // Start seamless infinite scroll - wrap at cycle width
                            // Using actualSpacing to match where images actually repeat (prevents jumping)
                            // Duration is 10.0 seconds (twice as slow as before)
                            startSeamlessScroll(cycleWidth: cycleWidth, duration: 10.0)
                        }
                        .onDisappear {
                            // Clean up timer
                            animationTimer?.invalidate()
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .zIndex(1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
    
    private func startSeamlessScroll(cycleWidth: CGFloat, duration: TimeInterval) {
        let pixelsPerSecond = cycleWidth / duration
        
        // Use a high-frequency timer for smooth updates
        var accumulatedTime: TimeInterval = 0
        let timerInterval = 1.0 / 120.0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            accumulatedTime += timerInterval
            
            // Calculate the raw offset based on accumulated time
            let rawOffset = -pixelsPerSecond * CGFloat(accumulatedTime)
            
            // Wrap seamlessly using modulo arithmetic
            // Convert to positive, apply modulo, then convert back to negative range
            // This ensures smooth, continuous wrapping without jumps
            let positiveOffset = -rawOffset
            let cyclesCompleted = floor(positiveOffset / cycleWidth)
            let remainder = positiveOffset - (cyclesCompleted * cycleWidth)
            let wrappedOffset = -remainder
            
            // Apply the wrapped offset smoothly
            offset = wrappedOffset
        }
    }
}

#Preview {
    SkyBackgroundView()
}
