//
//  GameModels.swift
//  Fd
//
//  Quantum Territories - A strategy game with quantum mechanics
//

import SwiftUI

// MARK: - Game Constants
enum GameConstants {
    static var gridSize = 6
    static let maxEnergy = 100
    static let captureThreshold = 3
    static let quantumCollapseChance: Double = 0.5 // Fixed to 50/50 for fairness
}

// MARK: - Player
enum Player: String, CaseIterable {
    case blue = "blue"
    case red = "red"
    case none = "none"
    
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .red: return Color(red: 1.0, green: 0.3, blue: 0.4)
        case .none: return Color.gray.opacity(0.3)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .blue: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .red: return Color(red: 1.0, green: 0.5, blue: 0.6)
        case .none: return Color.gray.opacity(0.5)
        }
    }
    
    var opposite: Player {
        switch self {
        case .blue: return .red
        case .red: return .blue
        case .none: return .none
        }
    }
}

// MARK: - Bot Difficulty
enum BotDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    
    var thinkingDelay: Double {
        switch self {
        case .easy: return 0.5
        case .medium: return 0.8
        case .hard: return 1.0
        case .expert: return 1.2
        }
    }
}

// MARK: - Quantum State
enum QuantumState {
    case collapsed(Player)      // Definitively belongs to a player
    case superposition          // Could be either player until observed
    case entangled(Int, Int)    // Linked to another cell
    
    var isCollapsed: Bool {
        if case .collapsed = self { return true }
        return false
    }
}

// MARK: - Cell
struct Cell: Identifiable {
    let id: Int
    let row: Int
    let col: Int
    var quantumState: QuantumState = .superposition
    var energy: Int = 0
    var pulsePhase: Double = 0
    var influenceBlue: Int = 0
    var influenceRed: Int = 0
    
    var owner: Player {
        if case .collapsed(let player) = quantumState {
            return player
        }
        return .none
    }
    
    var dominantInfluence: Player {
        if influenceBlue > influenceRed { return .blue }
        if influenceRed > influenceBlue { return .red }
        return .none
    }
    
    var totalInfluence: Int {
        influenceBlue + influenceRed
    }
    
    mutating func addInfluence(from player: Player, amount: Int = 1) {
        switch player {
        case .blue: influenceBlue += amount
        case .red: influenceRed += amount
        case .none: break
        }
    }
    
    func influence(for player: Player) -> Int {
        switch player {
        case .blue: return influenceBlue
        case .red: return influenceRed
        case .none: return 0
        }
    }
}

// MARK: - Game State
enum GamePhase {
    case placement       // Players place influence markers
    case observation     // Quantum states collapse
    case scoring         // Calculate territories
    case gameOver
}

// MARK: - Bot AI
class BotAI {
    let difficulty: BotDifficulty
    let player: Player
    private var recentMoves: [(Int, Int)] = [] // Track recent moves to avoid repetition
    
    init(difficulty: BotDifficulty, player: Player = .red) {
        self.difficulty = difficulty
        self.player = player
    }
    
    func chooseMove(cells: [[Cell]], gridSize: Int) -> (row: Int, col: Int)? {
        let move: (Int, Int)?
        
        switch difficulty {
        case .easy:
            move = chooseEasyMove(cells: cells, gridSize: gridSize)
        case .medium:
            move = chooseMediumMove(cells: cells, gridSize: gridSize)
        case .hard:
            move = chooseHardMove(cells: cells, gridSize: gridSize)
        case .expert:
            move = chooseExpertMove(cells: cells, gridSize: gridSize)
        }
        
        // Track move to avoid repetition
        if let m = move {
            recentMoves.append(m)
            if recentMoves.count > 5 {
                recentMoves.removeFirst()
            }
        }
        
        return move
    }
    
    // Penalty for recently used rows/columns to spread moves
    private func recentPenalty(row: Int, col: Int) -> Int {
        var penalty = 0
        for (r, c) in recentMoves {
            if r == row { penalty += 15 } // Same row penalty
            if c == col { penalty += 15 } // Same column penalty
            if r == row && c == col { penalty += 30 } // Same cell big penalty
        }
        return penalty
    }
    
    // MARK: - Easy: Spread out random moves
    private func chooseEasyMove(cells: [[Cell]], gridSize: Int) -> (row: Int, col: Int)? {
        var validMoves: [(row: Int, col: Int, score: Int)] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cells[row][col]
                if canInfluence(cell: cell) {
                    // Base random score
                    var score = Int.random(in: 0...100)
                    
                    // Penalize recently used areas
                    score -= recentPenalty(row: row, col: col)
                    
                    // Slightly prefer empty cells for variety
                    if cell.totalInfluence == 0 {
                        score += 20
                    }
                    
                    validMoves.append((row, col, score))
                }
            }
        }
        
        // Pick from top 5 moves randomly for variety
        let sortedMoves = validMoves.sorted { $0.score > $1.score }
        let topMoves = Array(sortedMoves.prefix(5))
        return topMoves.randomElement().map { ($0.row, $0.col) }
    }
    
    // MARK: - Medium: Balance strategy with spreading
    private func chooseMediumMove(cells: [[Cell]], gridSize: Int) -> (row: Int, col: Int)? {
        var scoredMoves: [(row: Int, col: Int, score: Int)] = []
        let opponent = player.opposite
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cells[row][col]
                if canInfluence(cell: cell) {
                    var score = Int.random(in: 0...30) // Base randomness
                    
                    // Spread penalty
                    score -= recentPenalty(row: row, col: col)
                    
                    // Can capture now
                    if cell.totalInfluence == 2 && cell.dominantInfluence == player {
                        score += 60
                    }
                    
                    // Block opponent capture
                    if cell.totalInfluence == 2 && cell.dominantInfluence == opponent {
                        score += 50
                    }
                    
                    // Continue building where we have influence
                    if cell.influence(for: player) > 0 && cell.totalInfluence < 2 {
                        score += 25
                    }
                    
                    // Start new positions on empty cells
                    if cell.totalInfluence == 0 {
                        score += 15
                    }
                    
                    // Entangled bonus
                    if case .entangled = cell.quantumState {
                        score += 20
                    }
                    
                    scoredMoves.append((row, col, score))
                }
            }
        }
        
        // Pick from top 3 moves
        let sortedMoves = scoredMoves.sorted { $0.score > $1.score }
        let topMoves = Array(sortedMoves.prefix(3))
        return topMoves.randomElement().map { ($0.row, $0.col) }
    }
    
    // MARK: - Hard: Smart strategy with variety
    private func chooseHardMove(cells: [[Cell]], gridSize: Int) -> (row: Int, col: Int)? {
        var scoredMoves: [(row: Int, col: Int, score: Int)] = []
        let opponent = player.opposite
        
        // Count current board state
        var ourCells = 0
        var theirCells = 0
        var emptyCells = 0
        
        for row in cells {
            for cell in row {
                if cell.owner == player { ourCells += 1 }
                else if cell.owner == opponent { theirCells += 1 }
                else { emptyCells += 1 }
            }
        }
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cells[row][col]
                if canInfluence(cell: cell) {
                    var score = Int.random(in: 0...15)
                    
                    // Spread penalty (less aggressive than medium)
                    score -= recentPenalty(row: row, col: col) / 2
                    
                    // PRIORITY 1: Capture if we're winning
                    if cell.totalInfluence == 2 {
                        if cell.influence(for: player) > cell.influence(for: opponent) {
                            score += 100 // Guaranteed win
                        } else if cell.influence(for: player) == cell.influence(for: opponent) {
                            score += 70 // 50/50, take the chance
                        } else {
                            score += 40 // Try to contest
                        }
                    }
                    
                    // PRIORITY 2: Block opponent captures
                    if cell.totalInfluence == 2 && cell.dominantInfluence == opponent {
                        score += 90
                    }
                    
                    // PRIORITY 3: Setup captures
                    if cell.totalInfluence == 1 && cell.influence(for: player) == 1 {
                        score += 45
                    }
                    
                    // PRIORITY 4: Disrupt opponent setups
                    if cell.totalInfluence == 1 && cell.influence(for: opponent) == 1 {
                        score += 35
                    }
                    
                    // Entanglement is powerful
                    if case .entangled(let entRow, let entCol) = cell.quantumState {
                        let entCell = cells[entRow][entCol]
                        score += 25
                        if entCell.totalInfluence == 1 || entCell.totalInfluence == 2 {
                            score += 30 // Could affect captures!
                        }
                    }
                    
                    // Expand to new areas (important for variety!)
                    if cell.totalInfluence == 0 {
                        score += 20
                        // Prefer corners and edges for control
                        let isEdge = row == 0 || row == gridSize-1 || col == 0 || col == gridSize-1
                        let isCorner = (row == 0 || row == gridSize-1) && (col == 0 || col == gridSize-1)
                        if isCorner { score += 15 }
                        else if isEdge { score += 8 }
                    }
                    
                    // Territory clustering
                    for dr in -1...1 {
                        for dc in -1...1 {
                            if dr == 0 && dc == 0 { continue }
                            let nr = row + dr
                            let nc = col + dc
                            if nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize {
                                let neighbor = cells[nr][nc]
                                if neighbor.owner == player {
                                    score += 6
                                }
                            }
                        }
                    }
                    
                    scoredMoves.append((row, col, score))
                }
            }
        }
        
        // Pick from top 2
        let sortedMoves = scoredMoves.sorted { $0.score > $1.score }
        if sortedMoves.count > 1 && Double.random(in: 0...1) > 0.7 {
            return (sortedMoves[1].row, sortedMoves[1].col)
        }
        return sortedMoves.first.map { ($0.row, $0.col) }
    }
    
    // MARK: - Expert: Optimal play with minimal repetition
    private func chooseExpertMove(cells: [[Cell]], gridSize: Int) -> (row: Int, col: Int)? {
        var scoredMoves: [(row: Int, col: Int, score: Int)] = []
        let opponent = player.opposite
        
        // Analyze board state
        var urgentCaptures: [(Int, Int, Int)] = []
        var urgentBlocks: [(Int, Int, Int)] = []
        var setupMoves: [(Int, Int, Int)] = []
        var expansionMoves: [(Int, Int, Int)] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cells[row][col]
                if canInfluence(cell: cell) {
                    var baseScore = Int.random(in: 0...5)
                    baseScore -= recentPenalty(row: row, col: col) / 3
                    
                    // Categorize moves
                    if cell.totalInfluence == 2 {
                        if cell.influence(for: player) >= cell.influence(for: opponent) {
                            urgentCaptures.append((row, col, 150 + baseScore))
                        }
                        if cell.dominantInfluence == opponent {
                            urgentBlocks.append((row, col, 140 + baseScore))
                        }
                    } else if cell.totalInfluence == 1 {
                        if cell.influence(for: player) == 1 {
                            setupMoves.append((row, col, 80 + baseScore))
                        } else {
                            setupMoves.append((row, col, 60 + baseScore)) // Disrupt
                        }
                    } else {
                        // Empty cell - calculate expansion value
                        var expansionScore = 30 + baseScore
                        
                        // Entanglement bonus
                        if case .entangled(let entRow, let entCol) = cell.quantumState {
                            let entCell = cells[entRow][entCol]
                            expansionScore += 35
                            if !entCell.quantumState.isCollapsed {
                                expansionScore += 20
                            }
                        }
                        
                        // Adjacency to our territory
                        for dr in -1...1 {
                            for dc in -1...1 {
                                if dr == 0 && dc == 0 { continue }
                                let nr = row + dr
                                let nc = col + dc
                                if nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize {
                                    let neighbor = cells[nr][nc]
                                    if neighbor.owner == player { expansionScore += 10 }
                                    if neighbor.influence(for: player) > 0 { expansionScore += 5 }
                                }
                            }
                        }
                        
                        // Strategic positions
                        let center = gridSize / 2
                        let distToCenter = abs(row - center) + abs(col - center)
                        if distToCenter <= 1 { expansionScore += 15 } // Center control
                        
                        expansionMoves.append((row, col, expansionScore))
                    }
                }
            }
        }
        
        // Priority: Captures > Blocks > Setups > Expansion
        if !urgentCaptures.isEmpty {
            scoredMoves = urgentCaptures
        } else if !urgentBlocks.isEmpty {
            scoredMoves = urgentBlocks
        } else if !setupMoves.isEmpty && Double.random(in: 0...1) > 0.3 {
            scoredMoves = setupMoves
        } else if !expansionMoves.isEmpty {
            scoredMoves = expansionMoves
        } else {
            scoredMoves = setupMoves + expansionMoves
        }
        
        // Pick best move with small chance for second best
        let sortedMoves = scoredMoves.sorted { $0.2 > $1.2 }
        if sortedMoves.count > 1 && Double.random(in: 0...1) > 0.85 {
            return (sortedMoves[1].0, sortedMoves[1].1)
        }
        return sortedMoves.first.map { ($0.0, $0.1) }
    }
    
    private func canInfluence(cell: Cell) -> Bool {
        // Can't influence opponent's collapsed cells
        if case .collapsed(let owner) = cell.quantumState {
            return owner == .none || owner == player
        }
        return true
    }
    
    func resetMemory() {
        recentMoves = []
    }
}

// MARK: - Game Model
@Observable
class GameModel {
    var cells: [[Cell]] = []
    var currentPlayer: Player = .blue
    var phase: GamePhase = .placement
    var blueScore: Int = 0
    var redScore: Int = 0
    var turnsRemaining: Int = 18
    var selectedCell: Cell? = nil
    var message: String = "Blue's turn - Place your influence"
    var isAnimating: Bool = false
    var collapsingCells: Set<Int> = []
    var gridSize: Int = 6
    
    // Bot support
    var botAI: BotAI? = nil
    var isVsBot: Bool = false
    var humanPlayer: Player = .blue
    var isBotThinking: Bool = false
    
    init() {
        resetGame()
    }
    
    func setupGame(gridSize: Int = 6, turns: Int = 18, botDifficulty: BotDifficulty? = nil, humanColor: Player = .blue) {
        self.gridSize = gridSize
        self.turnsRemaining = turns
        self.humanPlayer = humanColor
        
        if let difficulty = botDifficulty {
            self.isVsBot = true
            self.botAI = BotAI(difficulty: difficulty, player: humanColor.opposite)
        } else {
            self.isVsBot = false
            self.botAI = nil
        }
        
        resetGame()
    }
    
    func resetGame() {
        cells = []
        for row in 0..<gridSize {
            var rowCells: [Cell] = []
            for col in 0..<gridSize {
                let id = row * gridSize + col
                var cell = Cell(id: id, row: row, col: col)
                cell.pulsePhase = Double.random(in: 0...2 * .pi)
                rowCells.append(cell)
            }
            cells.append(rowCells)
        }
        
        // Start with human's color if vs bot
        currentPlayer = isVsBot ? humanPlayer : .blue
        phase = .placement
        blueScore = 0
        redScore = 0
        selectedCell = nil
        message = "\(currentPlayer == .blue ? "Blue" : "Red")'s turn - Tap a cell to influence"
        isAnimating = false
        collapsingCells = []
        isBotThinking = false
        
        // Reset bot memory for fresh game
        botAI?.resetMemory()
        
        // Create some initial entangled pairs
        createEntangledPairs()
        
        // If bot goes first
        if isVsBot && currentPlayer != humanPlayer {
            makeBotMove()
        }
    }
    
    private func createEntangledPairs() {
        // Create pairs based on grid size
        let pairCount = max(2, gridSize / 2)
        var availableCells = cells.flatMap { $0 }.map { $0.id }
        
        for _ in 0..<pairCount {
            guard availableCells.count >= 2 else { break }
            
            let idx1 = Int.random(in: 0..<availableCells.count)
            let id1 = availableCells.remove(at: idx1)
            let idx2 = Int.random(in: 0..<availableCells.count)
            let id2 = availableCells.remove(at: idx2)
            
            let row1 = id1 / gridSize
            let col1 = id1 % gridSize
            let row2 = id2 / gridSize
            let col2 = id2 % gridSize
            
            cells[row1][col1].quantumState = .entangled(row2, col2)
            cells[row2][col2].quantumState = .entangled(row1, col1)
        }
    }
    
    func tapCell(row: Int, col: Int) {
        guard phase == .placement, !isAnimating, !isBotThinking else { return }
        guard turnsRemaining > 0 else { return }
        
        // In bot mode, only allow human player's turns
        if isVsBot && currentPlayer != humanPlayer {
            return
        }
        
        processMove(row: row, col: col)
    }
    
    private func processMove(row: Int, col: Int) {
        var cell = cells[row][col]
        
        // Can't influence already collapsed cells owned by opponent
        if case .collapsed(let owner) = cell.quantumState, owner != .none, owner != currentPlayer {
            if currentPlayer == humanPlayer || !isVsBot {
                message = "Cannot influence opponent's collapsed territory!"
            }
            return
        }
        
        // Add influence
        cell.addInfluence(from: currentPlayer, amount: 1)
        
        // Check for collapse conditions
        let totalInfluence = cell.influenceBlue + cell.influenceRed
        if totalInfluence >= GameConstants.captureThreshold {
            collapseCell(row: row, col: col, cell: &cell)
        }
        
        cells[row][col] = cell
        
        // Handle entanglement
        if case .entangled(let entRow, let entCol) = cell.quantumState {
            var entangledCell = cells[entRow][entCol]
            entangledCell.addInfluence(from: currentPlayer, amount: 1)
            
            let entTotal = entangledCell.influenceBlue + entangledCell.influenceRed
            if entTotal >= GameConstants.captureThreshold {
                collapseCell(row: entRow, col: entCol, cell: &entangledCell)
            }
            
            cells[entRow][entCol] = entangledCell
        }
        
        turnsRemaining -= 1
        
        if turnsRemaining == 0 {
            startObservationPhase()
        } else {
            switchPlayer()
        }
    }
    
    private func collapseCell(row: Int, col: Int, cell: inout Cell) {
        let winner: Player
        
        if cell.influenceBlue > cell.influenceRed {
            winner = .blue
        } else if cell.influenceRed > cell.influenceBlue {
            winner = .red
        } else {
            // Fair 50/50 quantum randomness for ties
            winner = Double.random(in: 0...1) > 0.5 ? .blue : .red
        }
        
        cell.quantumState = .collapsed(winner)
        let cellId = cell.id
        collapsingCells.insert(cellId)
        
        // Remove from entangled state if needed
        if case .entangled(let entRow, let entCol) = cells[row][col].quantumState {
            if case .entangled = cells[entRow][entCol].quantumState {
                cells[entRow][entCol].quantumState = .superposition
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.collapsingCells.remove(cellId)
        }
    }
    
    private func switchPlayer() {
        currentPlayer = currentPlayer.opposite
        
        if isVsBot && currentPlayer != humanPlayer {
            message = "Bot is thinking..."
            makeBotMove()
        } else {
            message = "\(currentPlayer == .blue ? "Blue" : "Red")'s turn - Tap a cell to influence"
        }
    }
    
    private func makeBotMove() {
        guard let bot = botAI else { return }
        
        isBotThinking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + bot.difficulty.thinkingDelay) { [weak self] in
            guard let self = self else { return }
            
            if let move = bot.chooseMove(cells: self.cells, gridSize: self.gridSize) {
                self.isBotThinking = false
                self.processMove(row: move.row, col: move.col)
            } else {
                self.isBotThinking = false
            }
        }
    }
    
    func startObservationPhase() {
        phase = .observation
        message = "Observation Phase - Collapsing quantum states..."
        isAnimating = true
        
        // Collapse all remaining superposition cells
        collapseAllCells()
    }
    
    private func collapseAllCells() {
        var delay: Double = 0
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if !cells[row][col].quantumState.isCollapsed {
                    delay += 0.15
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        
                        var cell = self.cells[row][col]
                        let cellId = cell.id
                        self.collapsingCells.insert(cellId)
                        
                        let winner: Player
                        if cell.influenceBlue > cell.influenceRed {
                            winner = .blue
                        } else if cell.influenceRed > cell.influenceBlue {
                            winner = .red
                        } else {
                            // Fair 50/50 quantum randomness
                            winner = Double.random(in: 0...1) > 0.5 ? .blue : .red
                        }
                        
                        cell.quantumState = .collapsed(winner)
                        self.cells[row][col] = cell
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.collapsingCells.remove(cellId)
                        }
                    }
                }
            }
        }
        
        // After all cells collapse, calculate scores
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) { [weak self] in
            self?.calculateScores()
        }
    }
    
    private func calculateScores() {
        blueScore = 0
        redScore = 0
        
        for row in cells {
            for cell in row {
                if case .collapsed(let owner) = cell.quantumState {
                    if owner == .blue { blueScore += 1 }
                    else if owner == .red { redScore += 1 }
                }
            }
        }
        
        // Add territory bonus for connected regions
        let blueBonus = calculateTerritoryBonus(for: .blue)
        let redBonus = calculateTerritoryBonus(for: .red)
        blueScore += blueBonus
        redScore += redBonus
        
        phase = .gameOver
        isAnimating = false
        
        if blueScore > redScore {
            message = "Blue Wins! \(blueScore) - \(redScore)"
        } else if redScore > blueScore {
            message = "Red Wins! \(redScore) - \(blueScore)"
        } else {
            message = "It's a Tie! \(blueScore) - \(redScore)"
        }
    }
    
    func getGameResult() -> (won: Bool?, tied: Bool) {
        if blueScore == redScore {
            return (nil, true)
        }
        
        if isVsBot {
            let humanScore = humanPlayer == .blue ? blueScore : redScore
            let botScore = humanPlayer == .blue ? redScore : blueScore
            return (humanScore > botScore, false)
        }
        
        return (nil, false) // Two player mode - no single winner
    }
    
    private func calculateTerritoryBonus(for player: Player) -> Int {
        var visited = Set<Int>()
        var maxRegion = 0
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cells[row][col]
                if !visited.contains(cell.id), cell.owner == player {
                    let regionSize = floodFill(row: row, col: col, player: player, visited: &visited)
                    maxRegion = max(maxRegion, regionSize)
                }
            }
        }
        
        // Bonus points for largest connected territory
        return maxRegion >= 4 ? maxRegion / 2 : 0
    }
    
    private func floodFill(row: Int, col: Int, player: Player, visited: inout Set<Int>) -> Int {
        guard row >= 0, row < gridSize,
              col >= 0, col < gridSize else { return 0 }
        
        let cell = cells[row][col]
        guard !visited.contains(cell.id), cell.owner == player else { return 0 }
        
        visited.insert(cell.id)
        
        var count = 1
        count += floodFill(row: row - 1, col: col, player: player, visited: &visited)
        count += floodFill(row: row + 1, col: col, player: player, visited: &visited)
        count += floodFill(row: row, col: col - 1, player: player, visited: &visited)
        count += floodFill(row: row, col: col + 1, player: player, visited: &visited)
        
        return count
    }
}
