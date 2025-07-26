//
//  ContentView.swift
//  GrowBottle
//
//  Created by Shuhari on 7/26/25.
//

import SwiftUI
import SpriteKit

/// The main content view that displays an interactive bottle with physics simulation.
///
/// `ContentView` combines SpriteKit physics simulation with SwiftUI interface elements
/// to create an interactive bottle experience. The view manages the lifecycle of the
/// physics simulation and provides proper resource cleanup.
struct ContentView: View {
    
    // MARK: - Constants
    
    private enum Layout {
        /// Dimensions for the bottle container and physics scene
        static let bottleSize = CGSize(width: 290, height: 345)
        
        /// Dimensions for the bottle cap overlay
        static let capSize = CGSize(width: 240, height: 52)
        
        /// Vertical offset for cap positioning relative to bottle top
        static let capOffset: CGFloat = -31
        
        /// Asset names for bottle components
        enum Assets {
            static let bottle = "bottle"
            static let cap = "cap"
        }
    }
    
    // MARK: - State
    
    /// Tracks whether the scene is currently active for proper lifecycle management
    @State private var isSceneActive = false
    
    // MARK: - Properties
    
    /// The physics scene instance, created once and reused
    private let bottleScene: BottleScene = {
        let scene = BottleScene()
        scene.size = Layout.bottleSize
        scene.scaleMode = .aspectFit
        return scene
    }()
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            spriteView
            bottleImage
            capImage
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View Components

private extension ContentView {
    
    /// The SpriteKit view containing the physics simulation.
    ///
    /// This view hosts the bottle scene with physics objects and handles user interaction.
    /// Debug options are conditionally enabled based on build configuration.
    var spriteView: some View {
        SpriteView(
            scene: bottleScene,
            options: [.allowsTransparency],
            debugOptions: debugOptions
        )
        .frame(
            width: Layout.bottleSize.width,
            height: Layout.bottleSize.height
        )
        .background(Color.clear)
    }
    
    /// The main bottle image that serves as the visual container.
    ///
    /// This image provides the bottle appearance and should align with the physics
    /// boundaries defined in the scene.
    var bottleImage: some View {
        Image(Layout.Assets.bottle)
            .resizable()
            .frame(
                width: Layout.bottleSize.width,
                height: Layout.bottleSize.height
            )
    }
    
    /// The bottle cap image positioned at the top of the bottle.
    ///
    /// The cap is offset vertically to create the appearance of sitting on top
    /// of the bottle opening.
    var capImage: some View {
        Image(Layout.Assets.cap)
            .resizable()
            .frame(
                width: Layout.capSize.width,
                height: Layout.capSize.height
            )
            .offset(y: Layout.capOffset)
    }
    
    /// Debug options for SpriteKit view, conditionally enabled.
    ///
    /// Debug information is only displayed in debug builds to avoid performance
    /// impact and visual clutter in release builds.
    var debugOptions: SpriteView.DebugOptions {
        #if DEBUG
        return [.showsFPS, .showsFields, .showsPhysics, .showsNodeCount]
        #else
        return []
        #endif
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
