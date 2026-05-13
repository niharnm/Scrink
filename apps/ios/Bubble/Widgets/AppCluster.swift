import SwiftUI
import CoreMotion
import Foundation

// MARK: - Physics Engine

@Observable
final class ClusterPhysicsEngine {
    // Observed state (drives view updates)
    var positions: [CGPoint] = []
    var assignedPositions: [CGPoint] = []
    var draggingIndex: Int? = nil
    var longPressIndex: Int? = nil
    var containerSize: CGSize = .zero
    var originalCenter: CGPoint = .zero

    // Internal state (not observed by SwiftUI)
    @ObservationIgnored var velocities: [CGPoint] = []
    @ObservationIgnored var lastDragPosition: CGPoint? = nil
    @ObservationIgnored var lastDragTime: Date? = nil
    @ObservationIgnored var dragStartTime: Date? = nil
    @ObservationIgnored var rearrangementStartTime: Date? = nil
    @ObservationIgnored var plusIconOffset: CGPoint = .zero
    @ObservationIgnored private(set) var appCount: Int = 0
    @ObservationIgnored private var motionManager = CMMotionManager()
    @ObservationIgnored private var motionUpdateTimer: Timer?

    let centerSize: CGFloat = 96
    let mediumSize: CGFloat = 76
    let smallSize: CGFloat = 68

    deinit {
        stopMotionUpdates()
    }

    func getSize(for index: Int, appCount: Int) -> CGFloat {
        if index == 0 {
            return centerSize
        } else {
            return mediumSize
        }
    }

    func initializePositions(center: CGPoint, appCount: Int, containerSize: CGSize, hexPositions: [CGPoint]? = nil) {
        self.appCount = appCount
        self.containerSize = containerSize
        var newAssigned: [CGPoint] = []

        if let hexPositions = hexPositions, hexPositions.count == appCount {
            newAssigned = hexPositions
        } else {
            newAssigned.append(center)

            // Increase radius to ensure proper spacing - account for icon sizes
            // Medium icons are 76px, so we need at least 80-90px radius to avoid overlap
            // Add extra padding for better visual separation
            let iconSize = mediumSize
            let minSpacing: CGFloat = iconSize + 10 // Minimum spacing between icon centers
            let radius: CGFloat = max(90, minSpacing)
            let angleStep = (2 * .pi) / max(1, Double(appCount - 1))

            for i in 1..<appCount {
                let angle = angleStep * Double(i - 1)
                let x = center.x + radius * Foundation.cos(angle)
                let y = center.y + radius * Foundation.sin(angle)
                newAssigned.append(CGPoint(x: x, y: y))
            }
        }

        // Calculate plus icon position to avoid conflicts with app icons
        let plusSize = mediumSize
        let centerSize = self.centerSize
        
        // Find a good position for the plus icon that doesn't conflict with app icons
        // Try positions in a spiral pattern starting from top-right
        var plusPosition: CGPoint = center // Default initialization
        let candidateOffsets: [(CGFloat, CGFloat)] = [
            (60, -60),   // Top-right
            (80, -40),   // Further top-right
            (60, 60),    // Bottom-right
            (-60, -60),  // Top-left
            (-60, 60),   // Bottom-left
            (100, 0),   // Far right
            (-100, 0),  // Far left
            (0, 100),   // Far bottom
            (0, -100)   // Far top
        ]
        
        var foundPosition = false
        for (offsetX, offsetY) in candidateOffsets {
            let candidatePos = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
            
            // Check bounds
            let minX = max(center.x + (centerSize + plusSize) / 2, plusSize / 2)
            let maxX = containerSize.width - plusSize / 2
            let minY = max(center.y + (centerSize + plusSize) / 2, plusSize / 2)
            let maxY = containerSize.height - plusSize / 2
            
            if candidatePos.x < minX || candidatePos.x > maxX || candidatePos.y < minY || candidatePos.y > maxY {
                continue
            }
            
            // Check for conflicts with app icons
            var hasConflict = false
            for (index, appPos) in newAssigned.enumerated() {
                let appSize = getSize(for: index, appCount: appCount)
                let distance = sqrt(
                    pow(candidatePos.x - appPos.x, 2) +
                    pow(candidatePos.y - appPos.y, 2)
                )
                let minDistance = (plusSize + appSize) / 2 + 15 // Extra padding
                if distance < minDistance {
                    hasConflict = true
                    break
                }
            }
            
            if !hasConflict {
                plusPosition = candidatePos
                plusIconOffset = CGPoint(x: offsetX, y: offsetY)
                foundPosition = true
                break
            }
        }
        
        // Fallback: use default position with bounds checking
        if !foundPosition {
            let defaultOffsetX: CGFloat = 60
            let defaultOffsetY: CGFloat = -60
            plusIconOffset = CGPoint(x: defaultOffsetX, y: defaultOffsetY)
            
            let rawPlusPos = CGPoint(x: center.x + defaultOffsetX, y: center.y + defaultOffsetY)
            let minX = max(center.x + (centerSize + plusSize) / 2, plusSize / 2)
            let maxX = containerSize.width - plusSize / 2
            let minY = max(center.y + (centerSize + plusSize) / 2, plusSize / 2)
            let maxY = containerSize.height - plusSize / 2
            
            plusPosition = CGPoint(
                x: max(minX, min(maxX, rawPlusPos.x)),
                y: max(minY, min(maxY, rawPlusPos.y))
            )
        }
        
        newAssigned.append(plusPosition)

        assignedPositions = newAssigned
        positions = newAssigned
        velocities = Array(repeating: .zero, count: newAssigned.count)
        originalCenter = center
    }

    func updateAssignedPositions(hexPositions: [CGPoint]) {
        guard hexPositions.count == appCount else { return }
        for i in 0..<appCount {
            if i < assignedPositions.count {
                assignedPositions[i] = hexPositions[i]
            }
        }
    }

    func initialPosition(for index: Int, center: CGPoint, containerSize: CGSize, appCount: Int) -> CGPoint {
        if index < assignedPositions.count {
            return assignedPositions[index]
        }

        if index == 0 {
            return center
        } else if index < appCount {
            // Use same improved radius calculation as initializePositions
            let iconSize = mediumSize
            let minSpacing: CGFloat = iconSize + 10
            let radius: CGFloat = max(90, minSpacing)
            let angleStep = (2 * .pi) / max(1, Double(appCount - 1))
            let angle = angleStep * Double(index - 1)
            return CGPoint(
                x: center.x + radius * Foundation.cos(angle),
                y: center.y + radius * Foundation.sin(angle)
            )
        } else {
            let rawPosition = CGPoint(
                x: center.x + plusIconOffset.x,
                y: center.y + plusIconOffset.y
            )
            let plusSize = mediumSize
            let minX = max(center.x + (centerSize + plusSize) / 2, plusSize / 2)
            let maxX = containerSize.width - plusSize / 2
            let minY = max(center.y + (centerSize + plusSize) / 2, plusSize / 2)
            let maxY = containerSize.height - plusSize / 2
            return CGPoint(
                x: max(minX, min(maxX, rawPosition.x)),
                y: max(minY, min(maxY, rawPosition.y))
            )
        }
    }

    func updatePosition(at index: Int, to newPosition: CGPoint, appCount: Int) {
        guard index < positions.count else { return }

        if index == 0 {
            let size = getSize(for: index, appCount: appCount)
            let minX = size / 2
            let maxX = containerSize.width - size / 2
            let minY = size / 2
            let maxY = containerSize.height - size / 2

            positions[index] = CGPoint(
                x: max(minX, min(maxX, newPosition.x)),
                y: max(minY, min(maxY, newPosition.y))
            )
            return
        }

        let size = getSize(for: index, appCount: appCount)
        let minX = size / 2
        let maxX = containerSize.width - size / 2
        let minY = size / 2
        let maxY = containerSize.height - size / 2

        positions[index] = CGPoint(
            x: max(minX, min(maxX, newPosition.x)),
            y: max(minY, min(maxY, newPosition.y))
        )
    }

    func checkAndSwapPosition(draggedIndex: Int, dragPosition: CGPoint, appCount: Int) {
        guard draggedIndex > 0 && draggedIndex < appCount && draggedIndex < assignedPositions.count else { return }

        let swapThreshold: CGFloat = 40

        for otherIndex in 1..<appCount {
            if otherIndex != draggedIndex && otherIndex < assignedPositions.count {
                let otherAssignedPos = assignedPositions[otherIndex]
                let distance = sqrt(
                    pow(dragPosition.x - otherAssignedPos.x, 2) +
                    pow(dragPosition.y - otherAssignedPos.y, 2)
                )

                if distance < swapThreshold {
                    let temp = assignedPositions[draggedIndex]
                    assignedPositions[draggedIndex] = assignedPositions[otherIndex]
                    assignedPositions[otherIndex] = temp

                    if draggedIndex < positions.count && otherIndex < positions.count {
                        let tempPos = positions[draggedIndex]
                        positions[draggedIndex] = positions[otherIndex]
                        positions[otherIndex] = tempPos
                    }

                    if draggedIndex < velocities.count {
                        velocities[draggedIndex] = .zero
                    }
                    if otherIndex < velocities.count {
                        velocities[otherIndex] = .zero
                    }

                    break
                }
            }
        }
    }

    private func checkCollision(pos1: CGPoint, size1: CGFloat, pos2: CGPoint, size2: CGFloat) -> (collision: Bool, normalX: CGFloat, normalY: CGFloat, overlap: CGFloat) {
        let dx = pos2.x - pos1.x
        let dy = pos2.y - pos1.y
        let distance = sqrt(dx * dx + dy * dy)
        let minDistance = (size1 + size2) / 2 + 1

        if distance < minDistance && distance > 0.1 {
            let overlap = minDistance - distance
            return (true, dx / distance, dy / distance, overlap)
        }
        return (false, 0, 0, 0)
    }

    func startMotionUpdates() {
        motionUpdateTimer?.invalidate()

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.05
            motionManager.startDeviceMotionUpdates()
        }

        motionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.physicsStep()
        }
    }

    func stopMotionUpdates() {
        motionUpdateTimer?.invalidate()
        motionUpdateTimer = nil
        motionManager.stopDeviceMotionUpdates()
    }

    private func physicsStep() {
        guard !positions.isEmpty else { return }

        let motion = motionManager.deviceMotion
        let gravityX = motion?.gravity.x ?? 0.0
        let gravityY = motion?.gravity.y ?? 0.0

        let centerSpringConstant: CGFloat = 0.25
        let iconSpringConstant: CGFloat = 0.05
        let damping: CGFloat = 0.88
        let centerDamping: CGFloat = 0.85
        let deviceSensitivity: CGFloat = 1.5
        let maxVelocity: CGFloat = 25.0
        let collisionStiffness: CGFloat = 0.08
        let collisionDamping: CGFloat = 0.7
        let minVelocity: CGFloat = 0.1

        for i in 0..<positions.count {
            if i == draggingIndex { continue }

            while i >= velocities.count {
                velocities.append(.zero)
            }

            var currentPos = positions[i]
            var velocity = velocities[i]
            let size = getSize(for: i, appCount: appCount)

            // Plus icon: spring back to its fixed position (independent of center icon)
            if i == appCount {
                guard i < assignedPositions.count else { continue }

                let rawTargetPos = CGPoint(
                    x: originalCenter.x + plusIconOffset.x,
                    y: originalCenter.y + plusIconOffset.y
                )

                let pMinX = max(originalCenter.x + (centerSize + size) / 2, size / 2)
                let pMaxX = containerSize.width - size / 2
                let pMinY = max(originalCenter.y + (centerSize + size) / 2, size / 2)
                let pMaxY = containerSize.height - size / 2

                let targetPos = CGPoint(
                    x: max(pMinX, min(pMaxX, rawTargetPos.x)),
                    y: max(pMinY, min(pMaxY, rawTargetPos.y))
                )

                assignedPositions[i] = targetPos

                let dx = currentPos.x - targetPos.x
                let dy = currentPos.y - targetPos.y
                let distance = sqrt(dx * dx + dy * dy)

                let velMag = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
                if distance < 2.0 && velMag < 0.5 {
                    positions[i] = targetPos
                    velocities[i] = .zero
                    continue
                }

                if distance > 0.1 {
                    let directionX = -dx / distance
                    let directionY = -dy / distance
                    let springForce = iconSpringConstant * distance
                    velocity.x += springForce * directionX
                    velocity.y += springForce * directionY
                }
            }

            if i == 0 {
                let dx = currentPos.x - originalCenter.x
                let dy = currentPos.y - originalCenter.y
                let distance = sqrt(dx * dx + dy * dy)

                let velMag = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
                if distance < 2.0 && velMag < 0.5 {
                    positions[0] = originalCenter
                    velocities[0] = .zero
                    continue
                }

                if distance > 0.1 {
                    let directionX = -dx / distance
                    let directionY = -dy / distance
                    let springForce = centerSpringConstant * distance
                    velocity.x += springForce * directionX
                    velocity.y += springForce * directionY
                }
            } else if i < appCount {
                guard i < assignedPositions.count else { continue }
                let assignedPos = assignedPositions[i]
                let dx = currentPos.x - assignedPos.x
                let dy = currentPos.y - assignedPos.y
                let distance = sqrt(dx * dx + dy * dy)

                let velMag = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
                if distance < 2.0 && velMag < 0.5 {
                    positions[i] = assignedPos
                    velocities[i] = .zero
                    continue
                }

                if distance > 0.1 {
                    let directionX = -dx / distance
                    let directionY = -dy / distance
                    let springForce = iconSpringConstant * distance
                    velocity.x += springForce * directionX
                    velocity.y += springForce * directionY
                }
            }

            // Collision detection (all icons)
                for j in (i + 1)..<positions.count {
                    if j == draggingIndex { continue }

                    let otherPos = positions[j]
                    let otherSize = getSize(for: j, appCount: appCount)

                    let collision = checkCollision(
                        pos1: currentPos,
                        size1: size,
                        pos2: otherPos,
                        size2: otherSize
                    )

                    if collision.collision {
                        let separation = collision.overlap * 0.5

                        let moveX = -collision.normalX * separation
                        let moveY = -collision.normalY * separation
                        velocity.x += moveX * collisionStiffness * collisionDamping
                        velocity.y += moveY * collisionStiffness * collisionDamping

                        if j < velocities.count {
                            velocities[j].x += collision.normalX * separation * collisionStiffness * collisionDamping
                            velocities[j].y += collision.normalY * separation * collisionStiffness * collisionDamping
                        }

                        let minSeparation = (size + otherSize) / 2 + 1
                        let currentDistance = sqrt(
                            pow(otherPos.x - currentPos.x, 2) +
                            pow(otherPos.y - currentPos.y, 2)
                        )

                        if currentDistance < minSeparation && currentDistance > 0.1 {
                            let neededSeparation = (minSeparation - currentDistance) * 0.5
                            let correctionX = -collision.normalX * neededSeparation
                            let correctionY = -collision.normalY * neededSeparation

                            positions[i] = CGPoint(
                                x: currentPos.x + correctionX,
                                y: currentPos.y + correctionY
                            )
                            positions[j] = CGPoint(
                                x: otherPos.x - correctionX,
                                y: otherPos.y - correctionY
                            )

                            velocity.x *= 0.8
                            velocity.y *= 0.8
                            if j < velocities.count {
                                velocities[j].x *= 0.8
                                velocities[j].y *= 0.8
                            }

                            currentPos = positions[i]
                        }
                    }
                }

            // Device gravity (non-center icons only)
            if i > 0 {
                velocity.x += CGFloat(gravityX) * deviceSensitivity
                velocity.y -= CGFloat(gravityY) * deviceSensitivity
            }

            // Damping
            let currentDampingVal = i == 0 ? centerDamping : damping
            velocity.x *= currentDampingVal
            velocity.y *= currentDampingVal

            if i == 0 {
                let velMag = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
                if velMag < minVelocity {
                    velocity = .zero
                }
            }

            let velMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            if velMagnitude > maxVelocity {
                let scale = maxVelocity / velMagnitude
                velocity.x *= scale
                velocity.y *= scale
            }

            if velMagnitude < minVelocity {
                velocity = .zero
            }

            var newX = currentPos.x + velocity.x
            var newY = currentPos.y + velocity.y

            let boundsMinX = size / 2
            let boundsMaxX = containerSize.width - size / 2
            let boundsMinY = size / 2
            let boundsMaxY = containerSize.height - size / 2

            if newX < boundsMinX || newX > boundsMaxX {
                newX = max(boundsMinX, min(boundsMaxX, newX))
                velocity.x *= -0.5
            }
            if newY < boundsMinY || newY > boundsMaxY {
                newY = max(boundsMinY, min(boundsMaxY, newY))
                velocity.y *= -0.5
            }

            positions[i] = CGPoint(x: newX, y: newY)
            velocities[i] = velocity
        }
    }
}

// MARK: - AppCluster View

struct AppCluster: View {
    let apps: [BlockedApp]
    var onTapApp: (BlockedApp) -> Void
    var onTapAdd: () -> Void = {}
    var showAddButton: Bool = true

    @Environment(GridPositionStore.self) private var positionStore
    @State private var engine = ClusterPhysicsEngine()
    @State private var selectedApp: BlockedApp? = nil
    @State private var isEditMode = false
    @State private var hoveredHexSlot: HexCoordinate? = nil
    @State private var optionsService = AppOptionsService.shared
    @State private var lastToggledOptionId: String? = nil

    private let layoutManager = HexGridLayoutManager()

    private var gridRadius: Int {
        HexGridLayoutManager.gridRadius(for: apps.count)
    }

    private var gridSlots: [HexCoordinate] {
        HexCoordinate.hexesInRadius(gridRadius)
    }

    private var occupiedSlots: Set<HexCoordinate> {
        var set = Set<HexCoordinate>()
        for app in apps {
            if let hex = positionStore.position(for: app.id) {
                set.insert(hex)
            }
        }
        return set
    }

    private func hexPositionsForApps(center: CGPoint) -> [CGPoint] {
        apps.map { app in
            if let hex = positionStore.position(for: app.id) {
                return layoutManager.hexToPoint(hex, center: center)
            }
            return center
        }
    }

    private func initializeWithHexPositions(center: CGPoint, containerSize: CGSize) {
        let appIds = apps.map { $0.id }
        positionStore.assignDefaultPositions(for: appIds)
        let hexPoints = hexPositionsForApps(center: center)
        engine.initializePositions(center: center, appCount: apps.count, containerSize: containerSize, hexPositions: hexPoints)
    }

    private func recalculateAssignedPositions(center: CGPoint) {
        let hexPoints = hexPositionsForApps(center: center)
        engine.updateAssignedPositions(hexPositions: hexPoints)
    }

    private func positionForApp(at index: Int, center: CGPoint, containerSize: CGSize) -> CGPoint {
        if engine.positions.isEmpty || index >= engine.positions.count {
            if index < engine.assignedPositions.count {
                return engine.assignedPositions[index]
            } else {
                return engine.initialPosition(for: index, center: center, containerSize: containerSize, appCount: apps.count)
            }
        } else {
            return engine.positions[index]
        }
    }

    private func handleDragChanged(value: DragGesture.Value, index: Int, center: CGPoint, containerSize: CGSize) {
        if isEditMode {
            // In edit mode: center app (index 0) is locked
            guard index > 0 && index < apps.count else { return }

            if engine.draggingIndex == nil {
                engine.draggingIndex = index
            }
            if engine.draggingIndex == index {
                let newPosition = value.location
                engine.updatePosition(at: index, to: newPosition, appCount: apps.count)

                // Update hovered hex slot
                let nearest = layoutManager.nearestHex(to: newPosition, center: center)
                if gridSlots.contains(nearest) {
                    hoveredHexSlot = nearest
                } else {
                    hoveredHexSlot = nil
                }
            }
            return
        }

        // Normal mode drag behavior
        if engine.draggingIndex == nil {
            engine.draggingIndex = index
            engine.dragStartTime = Date()
        }

        if let startTime = engine.dragStartTime {
            let dragDuration = Date().timeIntervalSince(startTime)
            if dragDuration > 0.25 && !isEditMode && index > 0 && index < apps.count {
                // Enter edit mode
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditMode = true
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }

        if engine.draggingIndex == index && engine.lastDragPosition == nil {
            let initialPos: CGPoint
            if index < engine.positions.count {
                initialPos = engine.positions[index]
            } else if index < engine.assignedPositions.count {
                initialPos = engine.assignedPositions[index]
            } else {
                initialPos = engine.initialPosition(for: index, center: center, containerSize: containerSize, appCount: apps.count)
            }
            engine.lastDragPosition = initialPos
            engine.lastDragTime = Date()
        }
        if engine.draggingIndex == index {
            let newPosition = value.location
            engine.updatePosition(at: index, to: newPosition, appCount: apps.count)

            if isEditMode {
                let nearest = layoutManager.nearestHex(to: newPosition, center: center)
                if gridSlots.contains(nearest) {
                    hoveredHexSlot = nearest
                } else {
                    hoveredHexSlot = nil
                }
            } else if let rearrangingIndex = engine.longPressIndex, rearrangingIndex == index {
                engine.checkAndSwapPosition(draggedIndex: index, dragPosition: newPosition, appCount: apps.count)
            }

            updateVelocity(at: index, newPosition: newPosition)
        }
    }

    private func handleDragEnded(value: DragGesture.Value, index: Int, center: CGPoint, onTap: @escaping () -> Void) {
        if isEditMode && index > 0 && index < apps.count {
            // Snap to hex slot
            if let targetHex = hoveredHexSlot {
                let appId = apps[index].id
                positionStore.assignPosition(appId: appId, to: targetHex)
                recalculateAssignedPositions(center: center)
            }
            hoveredHexSlot = nil
            engine.draggingIndex = nil
            engine.dragStartTime = nil
            engine.lastDragPosition = nil
            engine.lastDragTime = nil
            return
        }

        applyReleaseVelocity(value: value, index: index)

        engine.draggingIndex = nil
        engine.dragStartTime = nil
        engine.lastDragPosition = nil
        engine.lastDragTime = nil

        if engine.longPressIndex == index {
            engine.longPressIndex = nil
            engine.rearrangementStartTime = nil
        }

        let dragDistance = sqrt(
            pow(value.location.x - value.startLocation.x, 2) +
            pow(value.location.y - value.startLocation.y, 2)
        )
        if dragDistance < 5 {
            onTap()
        }
    }

    private func updateVelocity(at index: Int, newPosition: CGPoint) {
        if let lastPos = engine.lastDragPosition, let lastTime = engine.lastDragTime {
            let timeDelta = Date().timeIntervalSince(lastTime)
            if timeDelta > 0 {
                let dx = newPosition.x - lastPos.x
                let dy = newPosition.y - lastPos.y
                let vel = CGPoint(x: dx / CGFloat(timeDelta), y: dy / CGFloat(timeDelta))
                if index < engine.velocities.count {
                    engine.velocities[index] = vel
                } else if index == engine.velocities.count {
                    engine.velocities.append(vel)
                }
            }
        }
        engine.lastDragPosition = newPosition
        engine.lastDragTime = Date()
    }

    private func applyReleaseVelocity(value: DragGesture.Value, index: Int) {
        if let lastPos = engine.lastDragPosition, let lastTime = engine.lastDragTime {
            let timeDelta = Date().timeIntervalSince(lastTime)
            if timeDelta > 0 {
                let dx = value.location.x - lastPos.x
                let dy = value.location.y - lastPos.y
                let releaseVelocity = CGPoint(
                    x: dx / CGFloat(timeDelta),
                    y: dy / CGFloat(timeDelta)
                )
                let velMag = sqrt(releaseVelocity.x * releaseVelocity.x + releaseVelocity.y * releaseVelocity.y)
                let maxReleaseVel: CGFloat = 200
                let finalVel: CGPoint
                if velMag > maxReleaseVel {
                    let scale = maxReleaseVel / velMag
                    finalVel = CGPoint(x: releaseVelocity.x * scale, y: releaseVelocity.y * scale)
                } else {
                    finalVel = releaseVelocity
                }
                if index < engine.velocities.count {
                    engine.velocities[index] = finalVel
                } else if index == engine.velocities.count {
                    engine.velocities.append(finalVel)
                }
            }
        }
    }

    @ViewBuilder
    private func appIconView(index: Int, center: CGPoint, geometry: GeometryProxy) -> some View {
        let app = apps[index]
        let size = engine.getSize(for: index, appCount: apps.count)
        let position = positionForApp(at: index, center: center, containerSize: geometry.size)
        let isSelected = selectedApp?.id == app.id
        let shouldHide = selectedApp != nil && !isSelected
        let isDraggingInEditMode = isEditMode && engine.draggingIndex == index

        AppIconCircle(
            iconName: app.iconName,
            size: size,
            platform: app.platform
        )
        .position(position)
        .scaleEffect(isDraggingInEditMode ? 1.15 : (engine.longPressIndex == index ? 1.1 : 1.0))
        .opacity(shouldHide ? 0 : 1)
        .shadow(color: isDraggingInEditMode ? .white.opacity(0.4) : .clear, radius: isDraggingInEditMode ? 10 : 0)
        .animation(.spring(response: 0.3), value: engine.longPressIndex)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedApp)
        .onTapGesture {
            if isEditMode {
                return
            }
            if engine.longPressIndex == nil {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    selectedApp = app
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if selectedApp == nil {
                        handleDragChanged(value: value, index: index, center: center, containerSize: geometry.size)
                    }
                }
                .onEnded { value in
                    handleDragEnded(value: value, index: index, center: center) {
                        if engine.longPressIndex == nil && selectedApp == nil && !isEditMode {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedApp = app
                            }
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private func plusIconView(center: CGPoint, geometry: GeometryProxy) -> some View {
        let plusIndex = apps.count
        let centerPosition: CGPoint = engine.positions.isEmpty ? center : engine.positions[0]
        let plusPosition: CGPoint = (engine.positions.isEmpty || plusIndex >= engine.positions.count)
            ? engine.initialPosition(for: plusIndex, center: centerPosition, containerSize: geometry.size, appCount: apps.count)
            : engine.positions[plusIndex]
        let shouldHide = selectedApp != nil || isEditMode

        AppIconCircle(iconName: "plus", size: engine.mediumSize, isAddButton: true)
            .position(plusPosition)
            .opacity(shouldHide ? 0 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedApp)
            .animation(.easeInOut(duration: 0.3), value: isEditMode)
            .onTapGesture {
                if selectedApp == nil && !isEditMode {
                    onTapAdd()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if selectedApp == nil && !isEditMode {
                            if engine.draggingIndex == nil {
                                engine.draggingIndex = plusIndex
                                let centerPos = engine.positions.count > 0 ? engine.positions[0] : center

                                let initialPos: CGPoint
                                if plusIndex < engine.positions.count {
                                    initialPos = engine.positions[plusIndex]
                                } else {
                                    initialPos = CGPoint(
                                        x: centerPos.x + engine.plusIconOffset.x,
                                        y: centerPos.y + engine.plusIconOffset.y
                                    )
                                }
                                engine.lastDragPosition = initialPos
                                engine.lastDragTime = Date()
                            }
                            if engine.draggingIndex == plusIndex {
                                let newPosition = value.location
                                engine.updatePosition(at: plusIndex, to: newPosition, appCount: apps.count)
                                updateVelocity(at: plusIndex, newPosition: newPosition)
                            }
                        }
                    }
                    .onEnded { value in
                        handleDragEnded(value: value, index: plusIndex, center: center) {
                            if selectedApp == nil && !isEditMode {
                                onTapAdd()
                            }
                        }
                    }
            )
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Background tap to exit edit mode
                if isEditMode {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEditMode = false
                                hoveredHexSlot = nil
                            }
                        }
                }

                // Enlarged view when app is selected
                if let selectedApp = selectedApp {
                    enlargedAppView(app: selectedApp, center: center, geometry: geometry)
                } else {
                    // Normal cluster view
                    ZStack {
                        // Hex grid overlay in edit mode
                        if isEditMode {
                            HexGridOverlay(
                                gridSlots: gridSlots,
                                occupiedSlots: occupiedSlots,
                                highlightedSlot: hoveredHexSlot,
                                center: center,
                                layoutManager: layoutManager
                            )
                            .transition(.opacity)
                        }

                        // Rearrangement mode indicators (non-edit-mode long press)
                        if !isEditMode, let rearrangingIndex = engine.longPressIndex, rearrangingIndex > 0 && rearrangingIndex < apps.count {
                            ForEach(1..<apps.count, id: \.self) { otherIndex in
                                if otherIndex != rearrangingIndex && otherIndex < engine.assignedPositions.count {
                                    let assignedPos = engine.assignedPositions[otherIndex]
                                    let size = engine.mediumSize
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: size, height: size)
                                        .position(assignedPos)
                                }
                            }
                        }

                        ForEach(0..<apps.count, id: \.self) { (index: Int) in
                            appIconView(index: index, center: center, geometry: geometry)
                        }

                        if showAddButton {
                            plusIconView(center: center, geometry: geometry)
                        }
                    }
                }
            }
            .onAppear {
                engine.containerSize = geometry.size
                engine.originalCenter = center
                initializeWithHexPositions(center: center, containerSize: geometry.size)
                if selectedApp == nil {
                    engine.startMotionUpdates()
                }
            }
            .onChange(of: selectedApp) { oldValue, newValue in
                if newValue == nil {
                    engine.startMotionUpdates()
                } else {
                    engine.stopMotionUpdates()
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                engine.containerSize = newSize
                if abs(newSize.width - oldSize.width) > 10 || abs(newSize.height - oldSize.height) > 10 {
                    let newCenter = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                    engine.originalCenter = newCenter
                    initializeWithHexPositions(center: newCenter, containerSize: newSize)
                }
            }
            .onDisappear {
                engine.stopMotionUpdates()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleCenterIconDrag(dragOffset: CGSize, center: CGPoint, options: [AppOption], appId: String) {
        guard !options.isEmpty else { return }
        
        let dragDistance = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        let minDragDistance: CGFloat = 30 // Minimum drag distance to trigger
        
        guard dragDistance >= minDragDistance else { return }
        
        // Calculate angle matching SwiftUI arc coordinate system
        // Screen: dragging up = negative y, dragging down = positive y
        // atan2(y, x): 0=right, positive=counter-clockwise, top=-.pi/2
        // SwiftUI arcs use clockwise: false (counter-clockwise), top=-.pi/2
        // Use atan2 directly since it matches the arc coordinate system
        let dragAngle = atan2(dragOffset.height, dragOffset.width)
        
        // Normalize to 0..2π for comparison with arc angles
        let normalizedDragAngle = dragAngle < 0 ? dragAngle + 2 * .pi : dragAngle
        
        // Find which arc this direction corresponds to
        let gapSize: CGFloat = 0.15
        let arcSize: CGFloat = (2 * .pi - (CGFloat(options.count) * gapSize)) / CGFloat(options.count)
        let topAngle: CGFloat = -.pi / 2
        let firstArcStart = topAngle - arcSize / 2
        
        // Normalize firstArcStart to 0..2π
        let normalizedFirstArcStart = firstArcStart < 0 ? firstArcStart + 2 * .pi : firstArcStart
        
        // Check each arc to see if the drag direction is within its range (with margin)
        let margin: CGFloat = arcSize * 0.4 // 40% margin on each side of centerline
        
        for (index, option) in options.enumerated() {
            let arcStart = normalizedFirstArcStart + (CGFloat(index) * (arcSize + gapSize))
            let arcMidpoint = arcStart + arcSize / 2
            
            // Normalize arc midpoint to 0..2π
            let normalizedArcMid = arcMidpoint >= 2 * .pi ? arcMidpoint - 2 * .pi : arcMidpoint
            
            // Check if drag angle is within margin of arc centerline
            var angleDiff = abs(normalizedDragAngle - normalizedArcMid)
            if angleDiff > .pi {
                angleDiff = 2 * .pi - angleDiff // Handle wrap-around
            }
            
            if angleDiff <= margin {
                // Only toggle if we haven't already toggled this option in this drag session
                if lastToggledOptionId != option.id {
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    optionsService.toggleOption(appId: appId, optionId: option.id)
                    lastToggledOptionId = option.id
                }
                break
            }
        }
    }
    
    @ViewBuilder
    private func enlargedAppView(app: BlockedApp, center: CGPoint, geometry: GeometryProxy) -> some View {
        let allOptions = optionsService.getAllOptions(for: app.id)
        
        ZStack {
            // Arcs around the icon
            if !allOptions.isEmpty {
                AppOptionArcs(
                    options: allOptions,
                    radius: 100,
                    lineWidth: 14,
                    onToggleOption: { optionId in
                        // Add haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        optionsService.toggleOption(appId: app.id, optionId: optionId)
                    }
                )
                .frame(width: 300, height: 300)
                .position(x: center.x, y: center.y - 75)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Large icon in center with drag gesture
            CenterIconWithDrag(
                app: app,
                center: center,
                options: allOptions,
                onDragChanged: { dragOffset, isDragStart in
                    if isDragStart {
                        lastToggledOptionId = nil // Reset when starting new drag
                    } else {
                        handleCenterIconDrag(
                            dragOffset: dragOffset,
                            center: center,
                            options: allOptions,
                            appId: app.id
                        )
                    }
                }
            )
            .transition(.opacity.combined(with: .scale))

            // App name text positioned between original and lower position
            Text(app.name.uppercased())
                .font(BubbleFonts.headerTitle)
                .foregroundStyle(.white)
                .position(x: center.x, y: center.y + 140)
            .transition(.opacity.combined(with: .scale))

            // Back button in bottom left - fades in separately at its position
            VStack {
                Spacer()
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedApp = nil
                        }
                    } label: {
                        BackArrowView(size: 34, color: .white)
                            .frame(width: 44, height: 44)
                            .background(BubbleColors.skyBlue)
                            .clipShape(Circle())
                    }
                    .padding(.leading, BubbleSpacing.xl + 10)
                    .padding(.bottom, 14)
                    .opacity(selectedApp != nil ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.15), value: selectedApp)

                    Spacer()
                }
            }
        }
    }
}

struct CenterIconWithDrag: View {
    let app: BlockedApp
    let center: CGPoint
    let options: [AppOption]
    let onDragChanged: (CGSize, Bool) -> Void // CGSize is offset, Bool is isDragStart
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    private let iconSize: CGFloat = 160
    private let arcRadius: CGFloat = 100
    private var maxRadius: CGFloat { arcRadius - 20 } // 80px max radius
    
    var body: some View {
        AppIconCircle(
            iconName: app.iconName,
            size: 160,
            platform: app.platform
        )
        .offset(dragOffset)
        .position(x: center.x, y: center.y - 75)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let wasDragging = isDragging
                    if !isDragging {
                        isDragging = true
                    }
                    // Limit movement within the radius
                    let distance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                    let clampedOffset: CGSize
                    if distance <= maxRadius {
                        clampedOffset = value.translation
                    } else {
                        // Clamp to max radius
                        let angle = atan2(value.translation.height, value.translation.width)
                        clampedOffset = CGSize(
                            width: maxRadius * cos(angle),
                            height: maxRadius * sin(angle)
                        )
                    }
                    dragOffset = clampedOffset
                    
                    // Trigger toggle check continuously as icon moves
                    // Pass true if this is the start of a new drag
                    onDragChanged(clampedOffset, !wasDragging)
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                    isDragging = false
                }
        )
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        AppCluster(
            apps: AppStore().apps,
            onTapApp: { _ in }
        )
        .environment(GridPositionStore())
    }
}
