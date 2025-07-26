//
//  CirclePackingAlgorithm.swift
//  GrowBottle
//
//  Created by Shuhari on 7/26/25.
//

import UIKit

/// A utility for efficiently packing circles within a rounded rectangle container.
///
/// `CirclePackingAlgorithm` provides methods to calculate optimal positions for circles
/// within a container while avoiding overlaps and respecting boundary constraints.
/// The algorithm uses a hybrid approach combining random placement with grid-based fallback
/// to achieve both natural distribution and guaranteed placement success.
struct CirclePackingAlgorithm {
    
    // MARK: - Constants
    
    private enum Constants {
        static let maxRandomAttempts = 1000
        static let boundaryInset: CGFloat = 4.0
        static let defaultMarginBuffer: CGFloat = 3.0
        static let circleSpacingMultiplier: CGFloat = 2.2
        static let minimumCircleSpacing: CGFloat = 2.2
    }
    
    // MARK: - Public Interface
    
    /// Packs circles within a rounded rectangle container using optimal positioning.
    ///
    /// This method attempts to place the specified number of circles within the container
    /// bounds while maintaining appropriate spacing and respecting the rounded corners.
    /// It uses a hybrid approach: first attempting random placement for natural distribution,
    /// then falling back to grid-based placement for guaranteed success.
    ///
    /// - Parameters:
    ///   - count: The number of circles to pack
    ///   - containerSize: The size of the container
    ///   - cornerRadius: The corner radius of the rounded rectangle container
    ///   - circleRadius: The radius of each circle to be packed
    /// - Returns: An array of `CGPoint` representing the center positions for each circle
    static func packCircles(count: Int,
                            containerSize: CGSize,
                            cornerRadius: CGFloat,
                            circleRadius: CGFloat) -> [CGPoint] {
        
        var positions: [CGPoint] = []
        let packingContext = PackingContext(
            containerSize: containerSize,
            cornerRadius: cornerRadius,
            circleRadius: circleRadius
        )
        
        for _ in 0..<count {
            if let position = findNextCirclePosition(
                existingPositions: positions,
                context: packingContext
            ) {
                positions.append(position)
            }
        }
        
        return positions
    }
}

// MARK: - Private Implementation

private extension CirclePackingAlgorithm {
    
    /// Context structure containing all parameters needed for circle packing calculations.
    struct PackingContext {
        let containerSize: CGSize
        let cornerRadius: CGFloat
        let circleRadius: CGFloat
        let margin: CGFloat
        let safeRect: CGRect
        
        init(containerSize: CGSize, cornerRadius: CGFloat, circleRadius: CGFloat) {
            self.containerSize = containerSize
            self.cornerRadius = cornerRadius
            self.circleRadius = circleRadius
            self.margin = circleRadius + Constants.defaultMarginBuffer
            
            // Calculate safe placement area
            self.safeRect = CGRect(
                x: Constants.boundaryInset + margin,
                y: Constants.boundaryInset + margin,
                width: containerSize.width - 2 * (Constants.boundaryInset + margin),
                height: containerSize.height - 2 * (Constants.boundaryInset + margin)
            )
        }
    }
    
    /// Finds the next available position for a circle using hybrid placement strategy.
    ///
    /// This method first attempts random placement within the safe area for natural
    /// distribution. If random placement fails after maximum attempts, it falls back
    /// to systematic grid-based placement starting from the center.
    ///
    /// - Parameters:
    ///   - existingPositions: Array of already placed circle positions
    ///   - context: Packing context containing container and circle parameters
    /// - Returns: A valid position for the next circle, or nil if no position is available
    static func findNextCirclePosition(existingPositions: [CGPoint],
                                       context: PackingContext) -> CGPoint? {
        
        // Attempt random placement first
        if let randomPosition = attemptRandomPlacement(
            existingPositions: existingPositions,
            context: context
        ) {
            return randomPosition
        }
        
        // Fall back to grid placement
        return attemptGridPlacement(
            existingPositions: existingPositions,
            context: context
        )
    }
    
    /// Attempts to place a circle at a random valid position.
    ///
    /// This method generates random candidate positions within the safe area
    /// and validates them against boundary constraints and existing circle positions.
    ///
    /// - Parameters:
    ///   - existingPositions: Array of already placed circle positions
    ///   - context: Packing context containing container and circle parameters
    /// - Returns: A valid random position, or nil if no position found within attempt limit
    static func attemptRandomPlacement(existingPositions: [CGPoint],
                                       context: PackingContext) -> CGPoint? {
        
        for _ in 0..<Constants.maxRandomAttempts {
            let candidate = generateRandomPosition(in: context.safeRect)
            
            if isValidCirclePosition(candidate, context: context) &&
               !hasCollisionWithExistingCircles(candidate, existingPositions: existingPositions, context: context) {
                return candidate
            }
        }
        
        return nil
    }
    
    /// Attempts to place a circle using systematic grid-based positioning.
    ///
    /// This method creates a grid pattern starting from the center and expanding
    /// outward in a spiral pattern to find the first available valid position.
    /// This ensures that placement will succeed even in crowded containers.
    ///
    /// - Parameters:
    ///   - existingPositions: Array of already placed circle positions
    ///   - context: Packing context containing container and circle parameters
    /// - Returns: A valid grid position, or nil if the container is completely full
    static func attemptGridPlacement(existingPositions: [CGPoint],
                                     context: PackingContext) -> CGPoint? {
        
        let spacing = context.circleRadius * Constants.circleSpacingMultiplier
        let gridDimensions = calculateGridDimensions(safeRect: context.safeRect, spacing: spacing)
        
        // Start spiral search from center
        let centerCol = gridDimensions.cols / 2
        let centerRow = gridDimensions.rows / 2
        
        for radius in 0..<max(gridDimensions.cols, gridDimensions.rows) {
            let spiralPositions = generateSpiralPositions(
                centerCol: centerCol,
                centerRow: centerRow,
                radius: radius,
                gridDimensions: gridDimensions
            )
            
            for (col, row) in spiralPositions {
                let candidate = calculateGridPosition(
                    col: col,
                    row: row,
                    safeRect: context.safeRect,
                    spacing: spacing
                )
                
                if isValidCirclePosition(candidate, context: context) &&
                   !hasCollisionWithExistingCircles(candidate, existingPositions: existingPositions, context: context) {
                    return candidate
                }
            }
        }
        
        return nil
    }
    
    /// Generates a random position within the specified rectangle.
    /// - Parameter rect: The bounding rectangle for position generation
    /// - Returns: A random `CGPoint` within the rectangle
    static func generateRandomPosition(in rect: CGRect) -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: rect.minX...rect.maxX),
            y: CGFloat.random(in: rect.minY...rect.maxY)
        )
    }
    
    /// Validates whether a position is suitable for circle placement.
    ///
    /// This method checks if the position is within the safe area and respects
    /// the rounded corner constraints of the container.
    ///
    /// - Parameters:
    ///   - position: The candidate position to validate
    ///   - context: Packing context containing container parameters
    /// - Returns: `true` if the position is valid, `false` otherwise
    static func isValidCirclePosition(_ position: CGPoint, context: PackingContext) -> Bool {
        // Basic boundary check
        guard context.safeRect.contains(position) else {
            return false
        }
        
        // Check rounded corner constraints
        return isPositionWithinRoundedCorners(position, context: context)
    }
    
    /// Checks if a position respects the rounded corner constraints.
    ///
    /// This method validates that circles placed near the corners of the container
    /// remain within the rounded boundary by calculating distance from corner centers.
    ///
    /// - Parameters:
    ///   - position: The position to validate
    ///   - context: Packing context containing corner radius and margin information
    /// - Returns: `true` if the position is within rounded corner bounds
    static func isPositionWithinRoundedCorners(_ position: CGPoint, context: PackingContext) -> Bool {
        let adjustedCornerRadius = context.cornerRadius - context.margin
        let safeRect = context.safeRect
        
        // Define corner center positions
        let cornerCenters = [
            CGPoint(x: safeRect.minX + adjustedCornerRadius, y: safeRect.minY + adjustedCornerRadius), // Bottom-left
            CGPoint(x: safeRect.maxX - adjustedCornerRadius, y: safeRect.minY + adjustedCornerRadius), // Bottom-right
            CGPoint(x: safeRect.minX + adjustedCornerRadius, y: safeRect.maxY - adjustedCornerRadius), // Top-left
            CGPoint(x: safeRect.maxX - adjustedCornerRadius, y: safeRect.maxY - adjustedCornerRadius)  // Top-right
        ]
        
        // Check each corner region
        for (index, cornerCenter) in cornerCenters.enumerated() {
            let dx = position.x - cornerCenter.x
            let dy = position.y - cornerCenter.y
            
            let isInCornerRegion = isPositionInCornerRegion(dx: dx, dy: dy, cornerIndex: index)
            
            if isInCornerRegion {
                let distanceFromCornerCenter = sqrt(dx * dx + dy * dy)
                if distanceFromCornerCenter > adjustedCornerRadius {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Determines if a position is within a specific corner region.
    /// - Parameters:
    ///   - dx: X distance from corner center
    ///   - dy: Y distance from corner center
    ///   - cornerIndex: Index of the corner (0: bottom-left, 1: bottom-right, 2: top-left, 3: top-right)
    /// - Returns: `true` if the position is in the specified corner region
    static func isPositionInCornerRegion(dx: CGFloat, dy: CGFloat, cornerIndex: Int) -> Bool {
        switch cornerIndex {
        case 0: return dx <= 0 && dy <= 0 // Bottom-left
        case 1: return dx >= 0 && dy <= 0 // Bottom-right
        case 2: return dx <= 0 && dy >= 0 // Top-left
        case 3: return dx >= 0 && dy >= 0 // Top-right
        default: return false
        }
    }
    
    /// Checks if a position would collide with any existing circles.
    ///
    /// This method calculates the minimum required distance between circles
    /// and verifies that the candidate position maintains appropriate spacing.
    ///
    /// - Parameters:
    ///   - position: The candidate position to check
    ///   - existingPositions: Array of already placed circle positions
    ///   - context: Packing context containing circle radius information
    /// - Returns: `true` if there would be a collision, `false` otherwise
    static func hasCollisionWithExistingCircles(_ position: CGPoint,
                                                existingPositions: [CGPoint],
                                                context: PackingContext) -> Bool {
        
        let minimumDistance = context.circleRadius * Constants.minimumCircleSpacing
        
        for existingPosition in existingPositions {
            let distance = calculateDistance(from: position, to: existingPosition)
            if distance < minimumDistance {
                return true
            }
        }
        
        return false
    }
    
    /// Calculates the Euclidean distance between two points.
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: The distance between the points
    static func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Grid dimension structure for organizing grid-based placement.
    struct GridDimensions {
        let cols: Int
        let rows: Int
    }
    
    /// Calculates grid dimensions based on available space and circle spacing.
    /// - Parameters:
    ///   - safeRect: The safe area for placement
    ///   - spacing: The spacing between grid positions
    /// - Returns: Grid dimensions structure
    static func calculateGridDimensions(safeRect: CGRect, spacing: CGFloat) -> GridDimensions {
        return GridDimensions(
            cols: Int(safeRect.width / spacing),
            rows: Int(safeRect.height / spacing)
        )
    }
    
    /// Generates spiral positions around a center point for systematic grid search.
    /// - Parameters:
    ///   - centerCol: Center column index
    ///   - centerRow: Center row index
    ///   - radius: Current spiral radius
    ///   - gridDimensions: Grid boundary constraints
    /// - Returns: Array of column-row pairs representing valid spiral positions
    static func generateSpiralPositions(centerCol: Int,
                                        centerRow: Int,
                                        radius: Int,
                                        gridDimensions: GridDimensions) -> [(col: Int, row: Int)] {
        
        guard radius >= 0 else { return [] }
        
        // Handle center point (radius 0)
        if radius == 0 {
            return [(col: centerCol, row: centerRow)]
        }
        
        var positions: [(col: Int, row: Int)] = []
        
        let minRow = max(0, centerRow - radius)
        let maxRow = min(gridDimensions.rows - 1, centerRow + radius)
        let minCol = max(0, centerCol - radius)
        let maxCol = min(gridDimensions.cols - 1, centerCol + radius)
        
        for row in minRow...maxRow {
            for col in minCol...maxCol {
                // Only include positions on the spiral perimeter
                if row == minRow || row == maxRow || col == minCol || col == maxCol {
                    positions.append((col: col, row: row))
                }
            }
        }
        
        return positions
    }
    
    /// Calculates the actual position for a grid cell.
    /// - Parameters:
    ///   - col: Column index
    ///   - row: Row index
    ///   - safeRect: The safe placement area
    ///   - spacing: Grid spacing
    /// - Returns: The calculated position
    static func calculateGridPosition(col: Int, row: Int, safeRect: CGRect, spacing: CGFloat) -> CGPoint {
        return CGPoint(
            x: safeRect.minX + CGFloat(col) * spacing,
            y: safeRect.minY + CGFloat(row) * spacing
        )
    }
}
