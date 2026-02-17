//
//  MainMenuView.swift
//  Fd
//
//  Quantum Territories - Main Menu & Dashboard
//

import SwiftUI

// MARK: - Game Mode
enum GameMode: String, CaseIterable, Identifiable {
    case twoPlayers = "Two Players"
    case botEasy = "vs Easy Bot"
    case botMedium = "vs Medium Bot"
    case botHard = "vs Hard Bot"
    case botExpert = "vs Expert Bot"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .twoPlayers: return "Play with a friend on the same device"
        case .botEasy: return "Random moves, perfect for beginners"
        case .botMedium: return "Some strategy, moderate challenge"
        case .botHard: return "Smart moves, tough opponent"
        case .botExpert: return "Optimal strategy, nearly unbeatable"
        }
    }
    
    var icon: String {
        switch self {
        case .twoPlayers: return "person.2.fill"
        case .botEasy: return "face.smiling"
        case .botMedium: return "brain"
        case .botHard: return "brain.head.profile"
        case .botExpert: return "cpu"
        }
    }
    
    var color: Color {
        switch self {
        case .twoPlayers: return .cyan
        case .botEasy: return .green
        case .botMedium: return .yellow
        case .botHard: return .orange
        case .botExpert: return .red
        }
    }
    
    var isBot: Bool {
        self != .twoPlayers
    }
    
    var botDifficulty: BotDifficulty? {
        switch self {
        case .twoPlayers: return nil
        case .botEasy: return .easy
        case .botMedium: return .medium
        case .botHard: return .hard
        case .botExpert: return .expert
        }
    }
}

// MARK: - Navigation
enum AppScreen: Hashable {
    case menu
    case game(GameMode)
    case settings
    case stats
}

// MARK: - Stats Manager
@Observable
class StatsManager {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var gamesLost: Int = 0
    var gamesTied: Int = 0
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
    
    func recordGame(won: Bool?, tied: Bool = false) {
        gamesPlayed += 1
        if tied {
            gamesTied += 1
        } else if let won = won {
            if won { gamesWon += 1 }
            else { gamesLost += 1 }
        }
    }
    
    func reset() {
        gamesPlayed = 0
        gamesWon = 0
        gamesLost = 0
        gamesTied = 0
    }
}

// MARK: - Settings Manager
@Observable
class SettingsManager {
    var gridSize: Int = 6
    var turnsPerGame: Int = 24
    var playerColor: Player = .blue
}

// MARK: - Main Menu View
struct MainMenuView: View {
    @Binding var currentScreen: AppScreen
    @State private var selectedMode: GameMode? = nil
    @State private var animateTitle = false
    @State private var showModes = false
    let stats: StatsManager
    
    var body: some View {
        ZStack {
            // Background
            AnimatedMenuBackground()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("QUANTUM")
                            .font(.system(size: 36, weight: .thin, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("TERRITORIES")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .shadow(color: .purple.opacity(0.5), radius: 20)
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0)
                
                Spacer()
                    .frame(height: 30)
                
                // Stats Card
                StatsCard(stats: stats)
                    .padding(.horizontal, 30)
                    .opacity(showModes ? 1 : 0)
                    .offset(y: showModes ? 0 : 20)
                
                Spacer()
                    .frame(height: 30)
                
                // Game Modes
                VStack(spacing: 12) {
                    Text("SELECT MODE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(4)
                    
                    ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        GameModeButton(mode: mode, isSelected: selectedMode == mode) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMode = mode
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    currentScreen = .game(mode)
                                }
                            }
                        }
                        .opacity(showModes ? 1 : 0)
                        .offset(y: showModes ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showModes)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Settings Button
                HStack(spacing: 20) {
                    MenuIconButton(icon: "gearshape.fill", label: "Settings") {
                        currentScreen = .settings
                    }
                    
                    MenuIconButton(icon: "chart.bar.fill", label: "Stats") {
                        currentScreen = .stats
                    }
                }
                .opacity(showModes ? 1 : 0)
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                showModes = true
            }
        }
    }
}

// MARK: - Animated Menu Background
struct AnimatedMenuBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            // Deep gradient
            let gradient = Gradient(colors: [
                Color(red: 0.02, green: 0.02, blue: 0.1),
                Color(red: 0.08, green: 0.04, blue: 0.18),
                Color(red: 0.02, green: 0.02, blue: 0.1)
            ])
            
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            
            // Glowing orbs
            let orbs: [(x: CGFloat, y: CGFloat, r: CGFloat, color: Color)] = [
                (0.2, 0.3, 150, .cyan.opacity(0.15)),
                (0.8, 0.2, 120, .purple.opacity(0.15)),
                (0.5, 0.7, 180, .pink.opacity(0.1)),
                (0.9, 0.8, 100, .blue.opacity(0.12))
            ]
            
            for orb in orbs {
                let x = orb.x * size.width + sin(phase + orb.r) * 20
                let y = orb.y * size.height + cos(phase + orb.r) * 15
                
                let gradient = Gradient(colors: [orb.color, orb.color.opacity(0)])
                context.fill(
                    Circle().path(in: CGRect(x: x - orb.r, y: y - orb.r, width: orb.r * 2, height: orb.r * 2)),
                    with: .radialGradient(gradient, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: orb.r)
                )
            }
            
            // Particles
            for i in 0..<80 {
                let x = (CGFloat(i) * 29 + phase * CGFloat(i % 7 + 1) * 0.5).truncatingRemainder(dividingBy: size.width)
                let y = (CGFloat(i) * 17 + phase * CGFloat(i % 5 + 1) * 0.3).truncatingRemainder(dividingBy: size.height)
                let radius = CGFloat(i % 4 + 1) * 0.6
                let opacity = 0.1 + Double(i % 6) * 0.08
                
                let color = [Color.cyan, .purple, .pink, .blue][i % 4].opacity(opacity)
                
                context.fill(
                    Circle().path(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(color)
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                phase = 1000
            }
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let stats: StatsManager
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(value: "\(stats.gamesPlayed)", label: "PLAYED", color: .cyan)
            StatItem(value: "\(stats.gamesWon)", label: "WON", color: .green)
            StatItem(value: "\(stats.gamesLost)", label: "LOST", color: .red)
            StatItem(value: String(format: "%.0f%%", stats.winRate), label: "WIN %", color: .purple)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Game Mode Button
struct GameModeButton: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundColor(mode.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(mode.description)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected ?
                        mode.color.opacity(0.2) :
                        Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? mode.color.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Menu Icon Button
struct MenuIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var currentScreen: AppScreen
    @Bindable var settings: SettingsManager
    let stats: StatsManager
    
    var body: some View {
        ZStack {
            AnimatedMenuBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { currentScreen = .menu }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("SETTINGS")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for alignment
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 70)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Game Settings
                        SettingsSection(title: "GAME") {
                            SettingsRow(icon: "square.grid.3x3", title: "Grid Size", color: .cyan) {
                                Picker("", selection: $settings.gridSize) {
                                    Text("5×5").tag(5)
                                    Text("6×6").tag(6)
                                    Text("7×7").tag(7)
                                    Text("8×8").tag(8)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                            
                            SettingsRow(icon: "clock", title: "Turns per Game", color: .purple) {
                                Picker("", selection: $settings.turnsPerGame) {
                                    Text("18").tag(18)
                                    Text("24").tag(24)
                                    Text("30").tag(30)
                                    Text("36").tag(36)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                            
                            SettingsRow(icon: "paintpalette", title: "Your Color", color: .pink) {
                                Picker("", selection: $settings.playerColor) {
                                    Text("Blue").tag(Player.blue)
                                    Text("Red").tag(Player.red)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                        }
                        
                        // Stats Reset
                        SettingsSection(title: "DATA") {
                            Button(action: { stats.reset() }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Reset Statistics")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        
                        // About
                        SettingsSection(title: "ABOUT") {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            content
        }
        .padding(.vertical, 12)
    }
}


// MARK: - Stats View
struct StatsView: View {
    @Binding var currentScreen: AppScreen
    let stats: StatsManager
    
    var body: some View {
        ZStack {
            AnimatedMenuBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { currentScreen = .menu }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("STATISTICS")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 70)
                
                VStack(spacing: 30) {
                    // Win Rate Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 20)
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .trim(from: 0, to: stats.winRate / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.0f%%", stats.winRate))
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("WIN RATE")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatBox(title: "Games Played", value: "\(stats.gamesPlayed)", icon: "gamecontroller", color: .cyan)
                        StatBox(title: "Victories", value: "\(stats.gamesWon)", icon: "trophy", color: .green)
                        StatBox(title: "Defeats", value: "\(stats.gamesLost)", icon: "xmark.circle", color: .red)
                        StatBox(title: "Draws", value: "\(stats.gamesTied)", icon: "equal.circle", color: .yellow)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

