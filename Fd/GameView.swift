//
//  GameView.swift
//  Fd
//
//  Quantum Territories - Beautiful Strategy Game UI
//

import SwiftUI

// MARK: - Main Game View
struct GameView: View {
    @Binding var currentScreen: AppScreen
    let gameMode: GameMode
    let settings: SettingsManager
    let stats: StatsManager
    
    @State private var game = GameModel()
    @State private var showRules = false
    @State private var showExitConfirm = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Header with back button
                    GameHeader(
                        game: game,
                        gameMode: gameMode,
                        showRules: $showRules,
                        onBack: {
                            if game.phase == .gameOver {
                                currentScreen = .menu
                            } else {
                                showExitConfirm = true
                            }
                        }
                    )
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Game Grid
                    GameGrid(game: game, size: min(geometry.size.width - 40, geometry.size.height - 320))
                    
                    Spacer()
                    
                    // Bottom Controls
                    BottomControls(game: game, onMenu: {
                        // Record stats if game over
                        if game.phase == .gameOver && gameMode.isBot {
                            let result = game.getGameResult()
                            stats.recordGame(won: result.won, tied: result.tied)
                        }
                        currentScreen = .menu
                    })
                    .padding(.bottom, 30)
                }
                
                // Bot thinking indicator
                if game.isBotThinking {
                    BotThinkingOverlay()
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showRules) {
            RulesView()
        }
        .alert("Leave Game?", isPresented: $showExitConfirm) {
            Button("Stay", role: .cancel) { }
            Button("Leave", role: .destructive) {
                currentScreen = .menu
            }
        } message: {
            Text("Your progress will be lost.")
        }
        .onAppear {
            game.setupGame(
                gridSize: settings.gridSize,
                turns: settings.turnsPerGame,
                botDifficulty: gameMode.botDifficulty,
                humanColor: settings.playerColor
            )
        }
        .onChange(of: game.phase) { oldPhase, newPhase in
            if newPhase == .gameOver && gameMode.isBot {
                let result = game.getGameResult()
                stats.recordGame(won: result.won, tied: result.tied)
            }
        }
    }
}

// MARK: - Bot Thinking Overlay
struct BotThinkingOverlay: View {
    @State private var dotCount = 0
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                .scaleEffect(1.5)
            
            Text("Bot thinking" + String(repeating: ".", count: dotCount))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            // Deep space gradient
            let gradient = Gradient(colors: [
                Color(red: 0.02, green: 0.02, blue: 0.08),
                Color(red: 0.05, green: 0.03, blue: 0.15),
                Color(red: 0.02, green: 0.02, blue: 0.08)
            ])
            
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            
            // Quantum particles
            for i in 0..<50 {
                let x = (CGFloat(i) * 37 + phase * CGFloat(i % 5 + 1) * 0.3).truncatingRemainder(dividingBy: size.width)
                let y = (CGFloat(i) * 23 + phase * CGFloat(i % 3 + 1) * 0.2).truncatingRemainder(dividingBy: size.height)
                let radius = CGFloat(i % 3 + 1) * 0.8
                let opacity = 0.1 + Double(i % 5) * 0.1
                
                let color = i % 2 == 0 ?
                    Color(red: 0.3, green: 0.6, blue: 1.0).opacity(opacity) :
                    Color(red: 1.0, green: 0.4, blue: 0.5).opacity(opacity)
                
                context.fill(
                    Circle().path(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(color)
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 1000
            }
        }
    }
}

// MARK: - Game Header
struct GameHeader: View {
    let game: GameModel
    let gameMode: GameMode
    @Binding var showRules: Bool
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Back button and title
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Menu")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Mode indicator
                HStack(spacing: 6) {
                    Image(systemName: gameMode.icon)
                        .foregroundColor(gameMode.color)
                    Text(gameMode.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(gameMode.color.opacity(0.15))
                )
            }
            .padding(.horizontal)
            
            // Title
            HStack {
                Text("QUANTUM")
                    .font(.system(size: 22, weight: .thin, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("TERRITORIES")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .shadow(color: .cyan.opacity(0.5), radius: 10)
            
            // Score Board
            HStack(spacing: 30) {
                ScoreView(
                    player: .blue,
                    score: game.blueScore,
                    isActive: game.currentPlayer == .blue && game.phase == .placement,
                    label: game.isVsBot ? (game.humanPlayer == .blue ? "YOU" : "BOT") : "BLUE"
                )
                
                VStack(spacing: 4) {
                    Text("TURNS")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(game.turnsRemaining)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                ScoreView(
                    player: .red,
                    score: game.redScore,
                    isActive: game.currentPlayer == .red && game.phase == .placement,
                    label: game.isVsBot ? (game.humanPlayer == .red ? "YOU" : "BOT") : "RED"
                )
            }
            
            // Message
            Text(game.message)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(
                                    game.currentPlayer == .blue ? Color.cyan.opacity(0.5) : Color.pink.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
            
            // Help button
            Button(action: { showRules = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                    Text("How to Play")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Score View
struct ScoreView: View {
    let player: Player
    let score: Int
    let isActive: Bool
    var label: String = ""
    
    @State private var pulseScale: CGFloat = 1.0
    
    var displayLabel: String {
        label.isEmpty ? (player == .blue ? "BLUE" : "RED") : label
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(displayLabel)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(player.accentColor)
            
            Text("\(score)")
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [player.color, player.accentColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(player.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(player.color.opacity(isActive ? 0.8 : 0.3), lineWidth: 2)
                )
        )
        .scaleEffect(pulseScale)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

// MARK: - Game Grid
struct GameGrid: View {
    let game: GameModel
    let size: CGFloat
    
    var cellSize: CGFloat {
        (size - CGFloat(game.gridSize - 1) * 4) / CGFloat(game.gridSize)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<game.gridSize, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<game.gridSize, id: \.self) { col in
                        CellView(
                            cell: game.cells[row][col],
                            game: game,
                            size: cellSize
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                game.tapCell(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: .purple.opacity(0.3), radius: 20)
    }
}

// MARK: - Cell View
struct CellView: View {
    let cell: Cell
    let game: GameModel
    let size: CGFloat
    
    @State private var quantumPhase: Double = 0
    @State private var isHovered = false
    
    var isCollapsing: Bool {
        game.collapsingCells.contains(cell.id)
    }
    
    var body: some View {
        ZStack {
            // Base shape
            RoundedRectangle(cornerRadius: 8)
                .fill(cellBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cellBorder, lineWidth: 1.5)
                )
            
            // Quantum effect for superposition
            if case .superposition = cell.quantumState {
                QuantumEffect(phase: quantumPhase, blueInfluence: cell.influenceBlue, redInfluence: cell.influenceRed)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Entangled indicator
            if case .entangled = cell.quantumState {
                EntangledIndicator(phase: quantumPhase)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Influence indicators
            VStack(spacing: 2) {
                if cell.influenceBlue > 0 || cell.influenceRed > 0 {
                    HStack(spacing: 4) {
                        if cell.influenceBlue > 0 {
                            InfluenceIndicator(count: cell.influenceBlue, player: .blue)
                        }
                        if cell.influenceRed > 0 {
                            InfluenceIndicator(count: cell.influenceRed, player: .red)
                        }
                    }
                }
            }
            
            // Collapse animation
            if isCollapsing {
                CollapseEffect()
            }
            
            // Collapsed state icon
            if case .collapsed(let owner) = cell.quantumState, owner != .none {
                Image(systemName: owner == .blue ? "waveform.circle.fill" : "waveform.circle.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(owner.accentColor)
                    .shadow(color: owner.color, radius: 5)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isCollapsing ? 1.2 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCollapsing)
        .onAppear {
            quantumPhase = cell.pulsePhase
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                quantumPhase += .pi * 2
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    var cellBackground: some ShapeStyle {
        switch cell.quantumState {
        case .collapsed(let owner):
            return AnyShapeStyle(owner.color.opacity(0.4))
        case .superposition:
            return AnyShapeStyle(Color.white.opacity(0.05))
        case .entangled:
            return AnyShapeStyle(Color.purple.opacity(0.2))
        }
    }
    
    var cellBorder: some ShapeStyle {
        switch cell.quantumState {
        case .collapsed(let owner):
            return AnyShapeStyle(owner.accentColor.opacity(0.8))
        case .superposition:
            let dominant = cell.dominantInfluence
            if dominant != .none {
                return AnyShapeStyle(dominant.color.opacity(0.5))
            }
            return AnyShapeStyle(Color.white.opacity(0.2))
        case .entangled:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.purple, .pink, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Quantum Effect
struct QuantumEffect: View {
    let phase: Double
    let blueInfluence: Int
    let redInfluence: Int
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Blue wave
            if blueInfluence > 0 {
                let blueOpacity = Double(blueInfluence) * 0.15
                for i in 0..<3 {
                    let offset = sin(phase + Double(i) * 0.5) * 3
                    let rect = CGRect(
                        x: center.x - 10 + offset,
                        y: center.y - 10 + CGFloat(i * 5),
                        width: 20,
                        height: 3
                    )
                    context.fill(
                        Ellipse().path(in: rect),
                        with: .color(Color.cyan.opacity(blueOpacity))
                    )
                }
            }
            
            // Red wave
            if redInfluence > 0 {
                let redOpacity = Double(redInfluence) * 0.15
                for i in 0..<3 {
                    let offset = cos(phase + Double(i) * 0.5) * 3
                    let rect = CGRect(
                        x: center.x - 10 + offset,
                        y: center.y - 5 + CGFloat(i * 5),
                        width: 20,
                        height: 3
                    )
                    context.fill(
                        Ellipse().path(in: rect),
                        with: .color(Color.pink.opacity(redOpacity))
                    )
                }
            }
        }
    }
}

// MARK: - Entangled Indicator
struct EntangledIndicator: View {
    let phase: Double
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Draw entanglement symbol (infinity-like pattern)
            for i in 0..<8 {
                let angle = (Double(i) / 8.0) * .pi * 2 + phase
                let radius: CGFloat = 8 + CGFloat(sin(angle * 2)) * 4
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius
                
                let particleSize: CGFloat = 2 + CGFloat(sin(angle + phase)) * 1
                
                context.fill(
                    Circle().path(in: CGRect(x: x - particleSize/2, y: y - particleSize/2, width: particleSize, height: particleSize)),
                    with: .color(Color.purple.opacity(0.6))
                )
            }
        }
    }
}

// MARK: - Influence Indicator
struct InfluenceIndicator: View {
    let count: Int
    let player: Player
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<min(count, 3), id: \.self) { _ in
                Circle()
                    .fill(player.accentColor)
                    .frame(width: 6, height: 6)
            }
            if count > 3 {
                Text("+")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(player.accentColor)
            }
        }
    }
}

// MARK: - Collapse Effect
struct CollapseEffect: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.white, .cyan, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 2
                    opacity = 0
                }
            }
    }
}

// MARK: - Bottom Controls
struct BottomControls: View {
    let game: GameModel
    let onMenu: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Reset button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    game.resetGame()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("RESTART")
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Observe button (only during placement with turns remaining)
            if game.phase == .placement && game.turnsRemaining > 0 && !game.isBotThinking {
                Button(action: {
                    withAnimation {
                        game.startObservationPhase()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("OBSERVE")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Menu button (show when game over)
            if game.phase == .gameOver {
                Button(action: onMenu) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("MENU")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Rules View
struct RulesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Spacer()
                        Text("HOW TO PLAY")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                    }
                    
                    RuleSection(
                        icon: "waveform.path",
                        title: "Quantum Superposition",
                        description: "Cells start in a quantum superposition - they don't belong to anyone until observed. Place your influence to sway the probability in your favor!"
                    )
                    
                    RuleSection(
                        icon: "hand.tap.fill",
                        title: "Placing Influence",
                        description: "Tap any cell to add your influence. Each player takes turns. The more influence you have on a cell, the more likely it collapses in your favor."
                    )
                    
                    RuleSection(
                        icon: "link",
                        title: "Entangled Cells",
                        description: "Some cells are quantum entangled (shown with purple glow). When you influence one, its entangled partner is automatically influenced too!"
                    )
                    
                    RuleSection(
                        icon: "eye.fill",
                        title: "Observation",
                        description: "When a cell reaches 3 total influence, it collapses! You can also press OBSERVE to end the game early and collapse all remaining cells."
                    )
                    
                    RuleSection(
                        icon: "trophy.fill",
                        title: "Scoring",
                        description: "Each collapsed cell = 1 point. Bonus points for having 4+ connected cells of the same color. Most points wins!"
                    )
                    
                    RuleSection(
                        icon: "dice.fill",
                        title: "Quantum Randomness",
                        description: "Tied influence? True quantum randomness decides! Even with less influence, there's always a chance..."
                    )
                    
                    Spacer(minLength: 40)
                    
                    Button(action: { dismiss() }) {
                        Text("GOT IT!")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Rule Section
struct RuleSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
