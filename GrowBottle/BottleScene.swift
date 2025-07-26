//
//  BottleScene.swift
//  GrowBottle
//
//  Created by Shuhari on 7/26/25.
//

import UIKit
import SpriteKit
import CoreMotion
import CoreHaptics
import AVFoundation

/// A physics-based scene that displays interactive spheres responding to device motion and providing haptic feedback.
///
/// `BottleScene` creates a bottle-like container with rounded boundaries containing various types of spheres
/// that respond to device orientation changes through Core Motion and provide tactile feedback through Core Haptics.
/// The scene supports different sphere types with varying quantities and handles collision detection between
/// spheres and boundaries.
class BottleScene: SKScene {
    
    // MARK: - Constants
    
    private enum Constants {
        static let sphereRadius: CGFloat = 20.0
        static let boundaryCornerRadius: CGFloat = 85.0
        static let boundaryInset: CGFloat = 4.0
        static let gravitySensitivity: Double = 15.0
        static let motionUpdateInterval: TimeInterval = 1.0 / 60.0
        static let hapticThrottleInterval: TimeInterval = 0.1
        static let maxCollisionSpeed: Float = 500.0
        static let maxBallCollisionSpeed: Float = 400.0
    }
    
    // MARK: - Properties
    
    private var motionManager: CMMotionManager!
    private var hapticEngine: CHHapticEngine?
    private var collisionPlayer: CHHapticPatternPlayer?
    private var lastHapticTime: TimeInterval = 0
    private var currentOrientation: UIDeviceOrientation = .portrait
    
    // App lifecycle observers
    private var appBecameActiveObserver: NSObjectProtocol?
    private var appWillResignActiveObserver: NSObjectProtocol?
    
    /// Collision categories for physics bodies using emoji for visual clarity.
    private enum 碰撞类型💥 {
        static let 小太阳🌞: UInt32 = 1     // 0001
        static let 边界🖼️: UInt32 = 2       // 0010
    }

    // MARK: - Scene Lifecycle
    
    /// Configures the scene when it's presented in a view.
    /// - Parameter view: The view that will display this scene.
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupPhysicsWorld()
        createBoundary()
        createSpheres()
        setupMotionManager()
        setupHapticEngine()
        setupAppLifecycleObservers()
    }
    
    /// Configures the physics world with appropriate settings for sphere simulation.
    private func setupPhysicsWorld() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 1
    }
    
    deinit {
        cleanupResources()
    }
}

// MARK: - Sphere Management

extension BottleScene {
    
    /// Available sphere types with their respective quantities.
    enum SphereType: String, CaseIterable {
        case perfect, nice, good
        
        /// The number of spheres to create for this type.
        var count: Int {
            switch self {
            case .perfect: return 7
            case .nice: return 5
            case .good: return 5
            }
        }
    }
    
    /// Creates and adds all spheres to the scene using circle packing algorithm.
    ///
    /// This method generates a shuffled collection of sphere types, calculates optimal positioning
    /// using circle packing, and creates physics-enabled spheres at those positions.
    private func createSpheres() {
        let sphereTypes = generateShuffledTypes()
        
        let positions = CirclePackingAlgorithm.packCircles(
            count: sphereTypes.count,
            containerSize: size,
            cornerRadius: Constants.boundaryCornerRadius,
            circleRadius: Constants.sphereRadius
        )
        
        for (index, type) in sphereTypes.enumerated() {
            let sphere = createSphere(
                type: type,
                radius: Constants.sphereRadius,
                at: positions[index]
            )
            addChild(sphere)
        }
    }
    
    /// Creates a single sphere with physics properties.
    /// - Parameters:
    ///   - type: The type of sphere to create
    ///   - radius: The radius of the sphere
    ///   - position: The initial position in the scene
    /// - Returns: A configured `SKSpriteNode` representing the sphere
    private func createSphere(type: SphereType, radius: CGFloat, at position: CGPoint) -> SKSpriteNode {
        let sphere = SKSpriteNode(imageNamed: type.rawValue, normalMapped: true)
        sphere.name = type.rawValue
        sphere.size = CGSize(width: radius * 2, height: radius * 2)
        sphere.position = position
        
        // Configure physics body with realistic properties
        sphere.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        sphere.physicsBody?.categoryBitMask = 碰撞类型💥.小太阳🌞
        sphere.physicsBody?.collisionBitMask = 碰撞类型💥.边界🖼️ | 碰撞类型💥.小太阳🌞
        sphere.physicsBody?.contactTestBitMask = 碰撞类型💥.小太阳🌞 | 碰撞类型💥.边界🖼️
        sphere.physicsBody?.restitution = 0.4
        sphere.physicsBody?.friction = 0.8
        sphere.physicsBody?.mass = 1.2
        sphere.physicsBody?.linearDamping = 0.4
        sphere.physicsBody?.angularDamping = 0.8
        
        return sphere
    }
    
    /// Generates a shuffled array of sphere types based on their individual counts.
    /// - Returns: A shuffled array containing all sphere instances
    private func generateShuffledTypes() -> [SphereType] {
        var types: [SphereType] = []
        for type in SphereType.allCases {
            types.append(contentsOf: Array(repeating: type, count: type.count))
        }
        return types.shuffled()
    }
}

// MARK: - Boundary Management

extension BottleScene {
    
    /// Creates the boundary that contains the spheres.
    ///
    /// The boundary is a rounded rectangle that acts as the container for all spheres.
    /// In debug builds, it also displays a visual representation of the boundary.
    private func createBoundary() {
        // Remove existing boundary if present
        childNode(withName: "Boundary")?.removeFromParent()
        
        let boundaryNode = SKNode()
        boundaryNode.name = "Boundary"
        
        let boundaryPath = createRoundedRectPath(
            size: size,
            cornerRadius: Constants.boundaryCornerRadius
        )
        
        // Configure physics body for edge-based collision
        boundaryNode.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryPath)
        boundaryNode.physicsBody?.categoryBitMask = 碰撞类型💥.边界🖼️
        boundaryNode.physicsBody?.collisionBitMask = 碰撞类型💥.小太阳🌞
        boundaryNode.physicsBody?.contactTestBitMask = 碰撞类型💥.小太阳🌞
        boundaryNode.physicsBody?.friction = 0.3
        boundaryNode.physicsBody?.restitution = 0.6
        
        #if DEBUG
        // Visual representation for debugging
        let shapeNode = SKShapeNode(path: boundaryPath)
        shapeNode.strokeColor = .red
        shapeNode.lineWidth = 2
        shapeNode.fillColor = .clear
        boundaryNode.addChild(shapeNode)
        #endif
        
        addChild(boundaryNode)
    }
    
    /// Creates a rounded rectangle path for the boundary.
    /// - Parameters:
    ///   - size: The size of the container
    ///   - cornerRadius: The radius for rounded corners
    /// - Returns: A `CGPath` representing the rounded rectangle
    private func createRoundedRectPath(size: CGSize, cornerRadius: CGFloat) -> CGPath {
        let rect = CGRect(
            x: Constants.boundaryInset,
            y: Constants.boundaryInset,
            width: size.width - Constants.boundaryInset * 2,
            height: size.height - Constants.boundaryInset * 2
        )
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        return path.cgPath
    }
}

// MARK: - Motion Management

extension BottleScene {
    
    /// Initializes and starts Core Motion for device orientation tracking.
    ///
    /// This method sets up the motion manager to track device motion and automatically
    /// adjusts the physics world's gravity based on device orientation changes.
    func setupMotionManager() {
        motionManager = CMMotionManager()
        
        // Enable device orientation notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        currentOrientation = UIDevice.current.orientation
        
        guard motionManager.isDeviceMotionAvailable else {
            print("设备不支持运动检测")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = Constants.motionUpdateInterval
        startMotionUpdates()
    }
    
    /// Starts receiving device motion updates.
    private func startMotionUpdates() {
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self,
                  let motion = motion else {
                if let error = error {
                    print("Motion update error: \(error.localizedDescription)")
                }
                return
            }
            
            self.handleMotionUpdate(motion)
        }
    }
    
    /// Handles device orientation changes.
    @objc private func orientationChanged() {
        currentOrientation = UIDevice.current.orientation
    }
    
    /// Transforms gravity vector based on device orientation.
    /// - Parameters:
    ///   - x: X component of gravity
    ///   - y: Y component of gravity
    ///   - orientation: Current device orientation
    /// - Returns: Transformed gravity components
    private func transformGravity(x: Double, y: Double, orientation: UIDeviceOrientation) -> (Double, Double) {
        switch orientation {
        case .portrait:
            return (x, y)
        case .portraitUpsideDown:
            return (-x, -y)
        case .landscapeLeft:
            return (-y, x)
        case .landscapeRight:
            return (y, -x)
        default:
            return (x, y)
        }
    }
    
    /// Processes motion updates and adjusts physics world gravity.
    /// - Parameter motion: The device motion data
    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity
        
        let (gravityX, gravityY) = transformGravity(
            x: gravity.x,
            y: gravity.y,
            orientation: currentOrientation
        )
        
        // Update physics world gravity with sensitivity scaling
        physicsWorld.gravity = CGVector(
            dx: CGFloat(gravityX * Constants.gravitySensitivity),
            dy: CGFloat(gravityY * Constants.gravitySensitivity)
        )
    }
    
    /// Stops motion updates and cleans up motion-related resources.
    func stopMotionUpdates() {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    /// Temporarily pauses motion updates.
    func pauseMotionUpdates() {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    /// Resumes motion updates after being paused.
    func resumeMotionUpdates() {
        startMotionUpdates()
    }
    
    /// Cleans up all motion-related resources.
    func cleanupMotionManager() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        stopMotionUpdates()
    }
}

// MARK: - Physics Contact Delegate

extension BottleScene: SKPhysicsContactDelegate {
    
    /// Handles collision detection between physics bodies.
    /// - Parameter contact: The contact information between two physics bodies
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Handle sphere-boundary collisions
        if collision == 碰撞类型💥.小太阳🌞 | 碰撞类型💥.边界🖼️ {
            handleSphereToWallCollision(contact: contact)
        }
        // Handle sphere-sphere collisions
        else if collision == 碰撞类型💥.小太阳🌞 {
            handleSphereToSphereCollision(contact: contact)
        }
    }
    
    /// Handles collisions between spheres and boundary walls.
    /// - Parameter contact: The contact information
    private func handleSphereToWallCollision(contact: SKPhysicsContact) {
        let ballBody = contact.bodyA.categoryBitMask == 碰撞类型💥.小太阳🌞 ?
            contact.bodyA : contact.bodyB
        let velocity = ballBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        let normalizedSpeed = min(max(Float(speed) / Constants.maxCollisionSpeed, 0.0), 1.0)
        playCollisionHaptic(intensity: normalizedSpeed)
    }
    
    /// Handles collisions between two spheres.
    /// - Parameter contact: The contact information
    private func handleSphereToSphereCollision(contact: SKPhysicsContact) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastHapticTime > Constants.hapticThrottleInterval else { return }
        lastHapticTime = currentTime
        
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let relativeVelocity = sqrt(
            pow(bodyA.velocity.dx - bodyB.velocity.dx, 2) +
            pow(bodyA.velocity.dy - bodyB.velocity.dy, 2)
        )
        
        let normalizedIntensity = min(max(Float(relativeVelocity) / Constants.maxBallCollisionSpeed, 0.0), 1.0)
        playCollisionHaptic(intensity: normalizedIntensity)
    }
}

// MARK: - Core Haptics

extension BottleScene {
    
    /// Initializes the haptic engine and sets up collision feedback patterns.
    ///
    /// This method configures Core Haptics for providing tactile feedback during collisions.
    /// It sets up the audio session, creates the haptic engine, and loads collision patterns.
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("设备不支持 Core Haptics")
            return
        }
        
        createHapticEngine()
        initializeCollisionHaptics()
    }
    
    /// Creates and configures the haptic engine.
    private func createHapticEngine() {
        do {
            // Configure audio session for haptics
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and start haptic engine
            hapticEngine = try CHHapticEngine(audioSession: .sharedInstance())
            try hapticEngine?.start()
            
            // Set up engine event handlers
            setupHapticEngineHandlers()
            
        } catch {
            print("Haptic Engine setup failed: \(error.localizedDescription)")
        }
    }
    
    /// Configures haptic engine event handlers for reset and stop events.
    private func setupHapticEngineHandlers() {
        hapticEngine?.resetHandler = { [weak self] in
            print("Haptic Engine Reset")
            do {
                try self?.hapticEngine?.start()
                self?.initializeCollisionHaptics()
            } catch {
                print("Failed to restart haptic engine: \(error.localizedDescription)")
            }
        }
        
        hapticEngine?.stoppedHandler = { reason in
            print("Haptic Engine Stopped: \(reason)")
        }
    }
    
    /// Initializes collision haptic patterns from AHAP files.
    private func initializeCollisionHaptics() {
        guard let engine = hapticEngine else { return }
        guard let patternURL = Bundle.main.url(forResource: "CollisionLarge", withExtension: "ahap") else {
            print("CollisionLarge.ahap file not found")
            return
        }
        
        do {
            let pattern = try CHHapticPattern(contentsOf: patternURL)
            collisionPlayer = try engine.makePlayer(with: pattern)
        } catch {
            print("初始化碰撞反馈失败: \(error.localizedDescription)")
        }
    }
    
    /// Temporarily pauses haptic feedback.
    func pauseHaptics() {
        print("Haptics Paused")
        hapticEngine?.stop()
        removeAppLifecycleObservers()
    }
    
    /// Resumes haptic feedback after being paused.
    func resumeHaptics() {
        print("Haptics Resumed")
        do {
            try hapticEngine?.start()
        } catch {
            print("恢复触觉引擎失败，尝试重建: \(error.localizedDescription)")
            createHapticEngine()
            initializeCollisionHaptics()
        }
        setupAppLifecycleObservers()
    }
    
    /// Sets up observers for app lifecycle events to manage haptic engine state.
    private func setupAppLifecycleObservers() {
        removeAppLifecycleObservers()
        
        appBecameActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            try? self?.hapticEngine?.start()
        }
        
        appWillResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hapticEngine?.stop()
        }
    }
    
    /// Removes app lifecycle observers.
    private func removeAppLifecycleObservers() {
        if let observer = appBecameActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            appBecameActiveObserver = nil
        }
        if let observer = appWillResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            appWillResignActiveObserver = nil
        }
    }
    
    /// Plays collision haptic feedback with variable intensity.
    /// - Parameter intensity: The intensity of the haptic feedback (0.0 to 1.0)
    func playCollisionHaptic(intensity: Float) {
        guard let player = collisionPlayer,
              intensity > 0.1,
              let engine = hapticEngine else { return }
        
        do {
            // Ensure engine is running
            try engine.start()
            
            // Configure dynamic parameters
            let intensityValue = linearInterpolation(alpha: intensity, min: 0.3, max: 1.0)
            let intensityParameter = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl,
                value: intensityValue,
                relativeTime: 0
            )
            
            let volumeValue = linearInterpolation(alpha: intensity, min: 0.1, max: 0.5)
            let volumeParameter = CHHapticDynamicParameter(
                parameterID: .audioVolumeControl,
                value: volumeValue,
                relativeTime: 0
            )
            
            // Send parameters and play
            try player.sendParameters([intensityParameter, volumeParameter], atTime: 0)
            try player.start(atTime: 0)
            
        } catch {
            print("Haptic Playback Failed: \(error.localizedDescription)")
        }
    }
    
    /// Performs linear interpolation between two values.
    /// - Parameters:
    ///   - alpha: The interpolation factor (0.0 to 1.0)
    ///   - min: The minimum value
    ///   - max: The maximum value
    /// - Returns: The interpolated value
    private func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }
    
    /// Cleans up all resources used by the scene.
    private func cleanupResources() {
        removeAppLifecycleObservers()
        cleanupMotionManager()
        hapticEngine?.stop()
        hapticEngine = nil
        collisionPlayer = nil
    }
}
