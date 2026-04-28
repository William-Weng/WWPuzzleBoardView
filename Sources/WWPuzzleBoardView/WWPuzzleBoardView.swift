//
//  WWPuzzleBoardView.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit

/// MARK: - 拼圖看板視圖
public final class WWPuzzleBoardView: UIView {
    
    public weak var delegate: WWPuzzleBoardView.Delegate?               // 拼圖看板的事件代理，用來回傳拖曳與互動狀態
    public var autoSortAnimationStyle: AnimationStyle = .manualLike     // 自動排序時使用的動畫風格設定
    
    private var configuration: Configuration = .init(rows: 3, cols: 3)  // 拼圖盤面配置 (3*3)
    
    private(set) var imageAsset: ImageAsset?                            // 目前拼圖使用的圖片資源
    public private(set) var boardState: BoardState?                     // 當前的拼圖狀態
    
    private var tileViews: [Int: TileView] = [:]                        // 目前已建立的 tile view，使用 tile ID 作為索引
    private var previousRenderedState: BoardState?                      // 上一次渲染完成的 board 狀態，用於比對並避免不必要的更新
    private var tileSize: CGSize { calculateTileSize() }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}

// MARK: - 公開函式
public extension WWPuzzleBoardView {
    
    /// 設定拼圖有幾塊 (rows * cols)
    /// - Parameters:
    ///   - rows: Int
    ///   - cols: Int
    func configure(rows: Int, cols: Int) {
        configuration = .init(rows: rows, cols: cols)
    }
    
    /// 使用原始圖片建立拼圖所需的圖片資源、初始 tile 狀態與初始畫面
    /// - Parameters:
    ///   - image: 原始拼圖圖片
    ///   - mode: 首次渲染時使用的模式，預設為立即更新
    func setup(with image: UIImage, mode: RenderMode = .instant) {
        
        let imageAsset = makeImageAsset(from: image, configuration: configuration)
        let tiles = makeSolvedTiles(rows: configuration.rows, cols: configuration.cols)
        let state = makeBoardState(tiles: tiles)
        
        setup(with: imageAsset, state: state, mode: mode)
    }
    
    /// 打亂目前拼圖位置，並以互動動畫更新畫面
    func shuffle() {
        
        guard let currentState = boardState else { return }
        
        var shuffledIndices = currentState.tiles.map(\.currentIndex)
        shuffledIndices.shuffle()
        
        let newTiles = currentState.tiles.enumerated().map { offset, tile -> Tile in
            var updatedTile = tile
            updatedTile.currentIndex = shuffledIndices[offset]
            return updatedTile
        }
        
        let newState = makeBoardState(tiles: newTiles)
        apply(newState, mode: .interactive, event: .didShuffle)
    }
    
    /// 將所有 tile 排回正確位置，並播放完成排序動畫
    func autoSort() {
        
        guard let currentState = boardState else { return }
        
        let newTiles = currentState.tiles.map { tile -> Tile in
            var updatedTile = tile
            updatedTile.currentIndex = updatedTile.correctIndex
            return updatedTile
        }
        
        let newState = makeBoardState(tiles: newTiles)
        apply(newState, mode: .solvedSequence, event: .didAutoSort)
    }
    
    /// 將所有 tile 直接排回正確位置
    /// - Parameter animated: 是否以互動動畫顯示整理過程
    func solve(animated: Bool = true) {
        
        guard let currentState = boardState else { return }
        
        let newTiles = currentState.tiles.map { tile -> Tile in
            var updatedTile = tile
            updatedTile.currentIndex = updatedTile.correctIndex
            return updatedTile
        }
        
        let newState = makeBoardState(tiles: newTiles)
        let mode: RenderMode = animated ? .interactive : .instant
        
        apply(newState, mode: mode, event: .didSolve)
    }
}

// MARK: - TileViewDelegate
extension WWPuzzleBoardView: WWPuzzleBoardView.TileViewDelegate {
    
    func tileViewDidBeginDragging(_ tileView: TileView) {
        tileViewDidBeginDragging(at: tileView)
    }
    
    func tileViewDidChangeDragging(_ tileView: TileView) {
        tileViewDidChangeDragging(at: tileView)
    }
    
    func tileViewDidEndDragging(_ tileView: TileView) {
        tileViewDidEndDragging(at: tileView)
    }
}

// MARK: - 小工具
private extension WWPuzzleBoardView {
    
    /// 共同的初始化
    func commonInit() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        clipsToBounds = true
    }
    
    /// 使用圖片資源與初始狀態建立拼圖畫面，並依指定模式完成首次渲染
    /// - Parameters:
    ///   - imageAsset: 拼圖使用的圖片資源
    ///   - state: 初始拼圖狀態
    ///   - mode: 首次渲染時使用的模式，預設為立即更新
    func setup(with imageAsset: ImageAsset, state: BoardState, mode: RenderMode = .instant) {
        
        self.imageAsset = imageAsset
        self.boardState = state
        
        rebuildBoard(with: imageAsset, tiles: state.tiles)
        render(state, mode: mode)
    }
    
    /// 根據圖片資源與 tile 資料建立拼圖畫面
    /// - Parameters:
    ///   - asset: 切割完成的拼圖圖片資源
    ///   - tiles: 初始 tile 狀態列表
    func rebuildBoard(with asset: ImageAsset, tiles: [Tile]) {
        
        clearTileViews()
        
        for tile in tiles {
            
            guard let image = asset.tileImages[tile.id] else { continue }
            
            let tileView = TileView(tileID: tile.id, image: image)
            
            tileView.boardView = self
            tileView.delegate = self
            tileView.frame = frameForCell(at: tile.currentIndex)
            
            addSubview(tileView)
            tileViews[tile.id] = tileView
        }
        
        previousRenderedState = nil
        setNeedsLayout()
    }
    
    /// 依照目前 state 重新配置所有 tile 的 frame，通常用於 layout 變更後的同步更新
    /// - Parameter state: 最新的 board 狀態
    func relayoutTiles(with state: BoardState) {
        
        for tile in state.tiles {
            guard let tileView = tileViews[tile.id] else { continue }
            tileView.frame = frameForCell(at: tile.currentIndex)
        }
        
        previousRenderedState = state
    }
    
    /// 根據指定的狀態與渲染模式更新整個拼圖畫面
    /// - Parameters:
    ///   - state: 最新的 board 狀態
    ///   - mode: 要使用的渲染模式，例如立即更新、互動動畫或完成序列動畫
    func render(_ state: BoardState, mode: RenderMode) {
        
        boardState = state
        updateHighlights(using: state, previous: previousRenderedState)
        
        switch mode {
        case .instant: applyFramesToAllTiles(using: state, mode: .instant)
        case .interactive: applyFramesToAllTiles(using: state, mode: .interactive)
        case .solvedSequence: applySolvedSequence(using: state)
        }
        
        bringDraggingTileToFront(using: state)
        previousRenderedState = state
    }
    
    /// 根據座標點換算其所在的格子索引，並限制結果不超出 board 邊界
    func cellIndex(containing point: CGPoint) -> Int {
        
        let col = min(max(Int(point.x / tileSize.width), 0), configuration.cols - 1)
        let row = min(max(Int(point.y / tileSize.height), 0), configuration.rows - 1)
        
        return row * configuration.cols + col
    }
}

// MARK: - TileViewDelegate
private extension WWPuzzleBoardView {
    
    /// 更新開始拖曳的狀態，並通知外部 delegate
    func tileViewDidBeginDragging(at tileView: TileView) {
        
        guard let currentState = boardState else { return }
        
        let newState = makeBoardState(tiles: currentState.tiles, draggingTileID: tileView.tileID, highlightedTargetTileID: nil)
        apply(newState, mode: .interactive, event: .didBeginDragging(tileID: tileView.tileID))
    }
    
    /// 根據拖曳中的 tile 目前中心點，計算目標格子並更新高亮狀態
    func tileViewDidChangeDragging(at tileView: TileView) {
        
        guard let currentState = boardState else { return }
        
        let targetCellIndex = cellIndex(containing: tileView.center)
        let targetTileID = currentState.tiles.first(where: { $0.currentIndex == targetCellIndex })?.id
        let newState = makeBoardState(tiles: currentState.tiles, draggingTileID: tileView.tileID, highlightedTargetTileID: targetTileID)
        
        apply(newState, mode: .interactive, event: .didChangeDragging(tileID: tileView.tileID, targetCellIndex: targetCellIndex))
    }
    
    /// 在拖曳結束時，將來源 tile 與目標格的 tile 交換位置，並更新 board state
    func tileViewDidEndDragging(at tileView: TileView) {
        
        guard let currentState = boardState else { return }
        
        let targetCellIndex = cellIndex(containing: tileView.center)
        
        guard let sourceTile = currentState.tiles.first(where: { $0.id == tileView.tileID }),
              let targetTile = currentState.tiles.first(where: { $0.currentIndex == targetCellIndex })
        else {
            return
        }
        
        let newTiles = currentState.tiles.map { tile -> Tile in
            
            var updatedTile = tile
            
            if tile.id == sourceTile.id {
                updatedTile.currentIndex = targetTile.currentIndex
            } else if tile.id == targetTile.id {
                updatedTile.currentIndex = sourceTile.currentIndex
            }
            
            return updatedTile
        }
        
        let newState = makeBoardState(tiles: newTiles)
        
        apply(newState, mode: .interactive, event: .didEndDragging(tileID: tileView.tileID, targetCellIndex: targetCellIndex))
        
        if newState.isSolved {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.applySolvedAppearance()
            }
        }
    }
}

// MARK: - 小工具
private extension WWPuzzleBoardView {

    /// 根據目前狀態更新所有 tile 的高亮顯示，僅在目標高亮有變化時才執行
    /// - Parameters:
    ///   - state: 最新的 board 狀態
    ///   - previous: 前一次的 board 狀態，用於判斷是否需要更新高亮
    func updateHighlights(using state: BoardState, previous: BoardState?) {
        
        guard previous == nil || previous?.highlightedTargetTileID != state.highlightedTargetTileID else { return }

        for tile in state.tiles {
            guard let tileView = tileViews[tile.id] else { continue }
            tileView.setTargetHighlighted(state.highlightedTargetTileID == tile.id, animated: false)
        }
    }
    
    /// 套用拼圖完成後的收尾動畫，讓完成瞬間有更明顯的視覺回饋 => 此方法不負責更新拼圖狀態，只在拼圖已完成後提供額外的視覺回饋。
    func applySolvedAppearance() {
        
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
        } completion: { _ in
            UIView.animate(withDuration: 0.12) {
                self.transform = .identity
            }
        }
    }
    
    /// 依照指定的渲染模式，將目前狀態中的所有 tile 套用到對應位置
    /// - Parameters:
    ///   - state: 最新的 board 狀態
    ///   - mode: 畫面更新時使用的渲染模式
    func applyFramesToAllTiles(using state: BoardState, mode: RenderMode) {
        
        for tile in state.tiles {
            guard let tileView = tileViews[tile.id] else { continue }
            applyFrameIfNeeded(for: tileView, tile: tile, draggingTileID: state.draggingTileID, mode: mode)
        }
    }

    /// 若 tile 目前不在正確位置，則依照渲染模式將其移動到目標 frame
    /// - Parameters:
    ///   - tileView: 畫面上對應的 tile view
    ///   - tile: tile 的狀態資料
    ///   - draggingTileID: 目前正在拖曳中的 tile ID，若該 tile 正在拖曳則不套用位置修正
    ///   - mode: 畫面更新時使用的渲染模式
    func applyFrameIfNeeded(for tileView: TileView, tile: Tile, draggingTileID: Int?, mode: RenderMode) {
        
        let targetFrame = frameForCell(at: tile.currentIndex)
        let isDragging = draggingTileID == tile.id
        let needsFrameCorrection = !tileView.frame.equalTo(targetFrame)
        
        guard !isDragging, needsFrameCorrection else { return }

        switch mode {
        case .instant: tileView.frame = targetFrame
        case .interactive: animateWithSpring { tileView.frame = targetFrame }
        case .solvedSequence: tileView.frame = targetFrame
        }
    }
    
    /// 以完成拼圖的順序播放自動排列動畫，讓 tile 依序回到目前狀態對應的位置s
    /// - Parameter state: 目前 board 的狀態資料，包含所有 tile 的位置與拖曳資訊
    func applySolvedSequence(using state: BoardState) {
        
        let animationStyle = autoSortAnimationStyle.setting()
        let sortedTiles = state.tiles.sorted { $0.correctIndex < $1.correctIndex }
        
        for (offset, tile) in sortedTiles.enumerated() {
            
            guard let tileView = tileViews[tile.id] else { continue }
            
            let targetFrame = frameForCell(at: tile.currentIndex)
            let isDragging = state.draggingTileID == tile.id
            let needsFrameCorrection = !tileView.frame.equalTo(targetFrame)
            
            guard !isDragging, needsFrameCorrection else { continue }
            
            let delay = Double(offset) * animationStyle.stepDelay
            let initialVelocity: CGVector = .init(dx: animationStyle.initialVelocity, dy: animationStyle.initialVelocity)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                
                BoardAnimationStyle.spring(duration: animationStyle.duration, dampingRatio: animationStyle.damping, initialVelocity: initialVelocity ).performAnimation {
                    tileView.transform = .identity
                    tileView.alpha = 1.0
                    tileView.frame = targetFrame
                }
            }
        }
    }
    
    /// 將目前正在拖曳的 tile 移到最上層，避免被其他 tile 遮住
    ///
    /// - Parameter state: 最新的 board 狀態
    func bringDraggingTileToFront(using state: BoardState) {
        
        guard let draggingID = state.draggingTileID,
              let draggingView = tileViews[draggingID]
        else {
            return
        }
        
        bringSubviewToFront(draggingView)
    }

    /// 使用預設的彈簧動畫執行畫面變化，適合互動中的位移與回彈效果
    /// - Parameter animations: 動畫期間要套用的屬性變化
    func animateWithSpring(_ animations: @escaping () -> Void) {
        BoardAnimationStyle.spring().performAnimation(animations: animations)
    }
}

// MARK: - 小工具
private extension WWPuzzleBoardView {
    
    /// 根據目前 board 尺寸與拼圖列數、行數，計算單一 tile 的顯示大小
    func calculateTileSize() -> CGSize {
        
        let width = bounds.width / CGFloat(configuration.cols)
        let height = bounds.height / CGFloat(configuration.rows)
        
        return .init(width: width, height: height)
    }
    
    /// 移除目前畫面上的所有 tile view，並清空內部快取
    func clearTileViews() {
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
    }
    
    /// 根據指定的格子索引，計算該 tile 在 board 中應該顯示的 frame
    func frameForCell(at index: Int) -> CGRect {
        
        let row = index / configuration.cols
        let col = index % configuration.cols
        
        return .init(x: CGFloat(col) * tileSize.width, y: CGFloat(row) * tileSize.height, width: tileSize.width, height: tileSize.height)
    }
}

// MARK: - 小工具
private extension WWPuzzleBoardView {
    
    /// 套用新的 board state，更新畫面並通知外部 delegate
    func apply(_ state: BoardState, mode: RenderMode, event: BoardEvent) {
        
        boardState = state
        render(state, mode: mode)
        
        switch event {
        case .didBeginDragging(let tileID): delegate?.puzzleBoardView(self, didBeginDraggingTileWithID: tileID, state: state)
        case .didChangeDragging(let tileID, let targetCellIndex): delegate?.puzzleBoardView(self, didChangeDraggingTileWithID: tileID, targetCellIndex: targetCellIndex, state: state)
        case .didEndDragging(let tileID, let targetCellIndex): delegate?.puzzleBoardView(self, didEndDraggingTileWithID: tileID, targetCellIndex: targetCellIndex, state: state)
        case .didShuffle: delegate?.puzzleBoardView(self, didUpdate: state)
        case .didSolve: delegate?.puzzleBoardView(self, didUpdate: state)
        case .didAutoSort: delegate?.puzzleBoardView(self, didUpdate: state)
        }
    }
}

// MARK: - 小工具
private extension WWPuzzleBoardView {
    
    /// 根據目前 tile 狀態建立對應的 board state，並自動計算完成數量與是否已解完
    /// - Parameters:
    ///   - tiles: 目前所有拼圖 tile 的狀態列表
    ///   - draggingTileID: 目前正在拖曳中的 tile ID；若沒有拖曳中的 tile 則為 `nil`
    ///   - highlightedTargetTileID: 目前被標示為交換目標的 tile ID；若沒有高亮目標則為 `nil`
    /// - Returns: 包含 tile 狀態、拖曳資訊、高亮目標、已完成數量與完成狀態的 `BoardState`
    func makeBoardState(tiles: [WWPuzzleBoardView.Tile], draggingTileID: Int? = nil, highlightedTargetTileID: Int? = nil) -> WWPuzzleBoardView.BoardState {
        
        let correctCount = tiles.filter { $0.currentIndex == $0.correctIndex }.count
        let isSolved = (correctCount == tiles.count)
        
        return .init(tiles: tiles, draggingTileID: draggingTileID, highlightedTargetTileID: highlightedTargetTileID, correctCount: correctCount, isSolved: isSolved)
    }
    
    /// 建立已完成狀態的 tile 列表，並依照列數與行數計算每片 tile 在原圖中的來源區域
    /// - Parameters:
    ///   - rows: 直行數
    ///   - cols: 橫列數
    /// - Returns: [WWPuzzleBoardView.Tile]
    func makeSolvedTiles(rows: Int, cols: Int) -> [WWPuzzleBoardView.Tile] {
        
        let count = rows * cols
        
        return (0..<count).map { index in
            
            let row = index / cols
            let col = index % cols
            
            let sourceRect = CGRect(x: CGFloat(col) / CGFloat(cols), y: CGFloat(row) / CGFloat(rows), width: 1.0 / CGFloat(cols), height: 1.0 / CGFloat(rows))
            
            return .init(id: index, correctIndex: index, sourceRect: sourceRect, currentIndex: index)
        }
    }
        
    /// 根據原始圖片與拼圖配置切出所有 tile 圖片，並建立對應的圖片資源
    /// - Parameters:
    ///   - image: 原始拼圖圖片
    ///   - configuration: 拼圖看板的列數與行數設定
    /// - Returns: 包含原始圖片、CGImage 與所有 tile 小圖的 `ImageAsset`
    func makeImageAsset(from image: UIImage, configuration: WWPuzzleBoardView.Configuration) -> WWPuzzleBoardView.ImageAsset {
        
        var tileImages: [Int: UIImage] = [:]
        
        let rows = configuration.rows
        let cols = configuration.cols
        
        guard let cgImage = image.cgImage else { fatalError("Failed to create CGImage from UIImage.") }
        
        let tileWidth = cgImage.width / cols
        let tileHeight = cgImage.height / rows
        
        for index in 0..<(rows * cols) {
            
            let row = index / cols
            let col = index % cols
            
            let rect = CGRect(x: col * tileWidth, y: row * tileHeight, width: tileWidth, height: tileHeight)
            
            guard let cropped = cgImage.cropping(to: rect) else { continue }
            tileImages[index] = UIImage(cgImage: cropped)
        }
        
        return .init(image: image, cgImage: cgImage, tileImages: tileImages)
    }
}
