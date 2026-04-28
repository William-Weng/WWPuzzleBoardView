//
//  WWPuzzleBoardView.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit
import CoreGraphics

// MARK: - 公開模型
public extension WWPuzzleBoardView {
    
    /// 拼圖顯示所需的影像素材集合 => 預覽圖與拼圖塊共用同一份來源資料
    struct ImageAsset {
        
        let image: UIImage                      // 保留原始（已 normalize 後）的完整 UIImage，方便預覽或其他 UI 顯示
        let cgImage: CGImage                    // 保留底層 CGImage，方便後續做像素層級處理或裁切
        let tileImages: [Int: UIImage]          // 每個 tile id 對應的切圖結果 => key: 0 -> 第 0 塊拼圖圖片 / key: 1 -> 第 1 塊拼圖圖片
        
        public init(image: UIImage, cgImage: CGImage, tileImages: [Int : UIImage]) {
            self.image = image
            self.cgImage = cgImage
            self.tileImages = tileImages
        }
    }
    
    /// 單一拼圖塊的資料模型 => 這個型別只描述「這塊圖是誰、原本應該在哪裡、現在在哪裡」，不負責畫面顯示
    struct Tile: Identifiable, Equatable {
        
        public let id: Int                      // 這塊拼圖的唯一識別值
        
        public let correctIndex: Int            // 這塊拼圖在完成狀態下應該所在的格子 index => (0, 1, 2) / (3, 4, 5) / (6, 7, 8)
        public let sourceRect: CGRect           // 這塊拼圖對應到原圖中的裁切區域 => 每個 Tile 各自記住自己在原圖裡應該取哪一塊
        
        public var currentIndex: Int            // 這塊拼圖目前實際位於哪個格子 => 功能中拖曳、交換、shuffle、solve，改變的通常就是這個值
        
        public init(id: Int, correctIndex: Int, sourceRect: CGRect, currentIndex: Int) {
            self.id = id
            self.correctIndex = correctIndex
            self.sourceRect = sourceRect
            self.currentIndex = currentIndex
        }
    }
    
    /// 整個拼圖盤面的狀態 => 這樣可以把「畫面呈現」和「遊戲規則」清楚分開。
    struct BoardState: Equatable {
        
        static let empty = emptyBoardState()            // 空白初始狀態 (預設值)
        
        public var tiles: [Tile]                        // 目前盤面上所有 tile 的狀態 => 這裡的 tile 陣列通常不一定依 currentIndex 排序，真正顯示時，會根據每個 tile 的 currentIndex 去算 frame。
        public var draggingTileID: Int?                 // 正在被拖曳的 tile id => 若有值，通常代表該 tile：要被拉到最上層顯示 / 可能套用拖曳中的縮放 / 陰影樣式
        public var highlightedTargetTileID: Int?        // 目前被高亮標示的目標 tile id => 例如拖曳某塊到另一格上方時，可以用這個欄位讓目標 tile 顯示高亮效果
        public var correctCount: Int                    // 目前已經放到正確位置的 tile 數量 => tiles.filter { $0.currentIndex == $0.correctIndex }.count
        public var isSolved: Bool                       // 盤面是否已完成 => 一般會在 correctCount == tiles.count 時設為 true。
        
        public init(tiles: [Tile], draggingTileID: Int? = nil, highlightedTargetTileID: Int? = nil, correctCount: Int, isSolved: Bool) {
            self.tiles = tiles
            self.draggingTileID = draggingTileID
            self.highlightedTargetTileID = highlightedTargetTileID
            self.correctCount = correctCount
            self.isSolved = isSolved
        }
        
        /// 空白初始狀態 (預設值)
        /// - Returns: Self
        static private func emptyBoardState() -> Self {
            return .init(tiles: [], draggingTileID: nil, highlightedTargetTileID: nil, correctCount: 0, isSolved: false)
        }
    }
    
    /// 拼圖盤面配置
    struct Configuration: Equatable {
        
        static let `default` = defaultValue()
        
        public let rows: Int
        public let cols: Int
        
        var tileCount: Int { return calculateTileCount() }
        
        /// 建立拼圖盤面配置
        /// - Parameters:
        ///   - rows: 拼圖總列數 => 例如 rows = 3 代表拼圖會分成 3 列
        ///   - cols: 拼圖總欄數 => 例如 cols = 3 代表拼圖會分成 3 欄
        public init(rows: Int, cols: Int) {
            precondition(rows > 0 && cols > 0, "rows and cols must be greater than zero")
            self.rows = rows
            self.cols = cols
        }
        
        /// 預設盤面配置 => 目前預設為 3 x 3，也就是常見的九宮格拼圖
        /// - Returns: Self
        static private func defaultValue() -> Self {
            return .init(rows: 3, cols: 3)
        }
        
        /// 拼圖總塊數 => 例如 3 x 3 = 9 塊、4 x 4 = 16 塊。
        /// - Returns: Int
        private func calculateTileCount() -> Int {
            return rows * cols
        }
    }
}

// MARK: - 模型
extension WWPuzzleBoardView {
    
    /// 定義自動排序功能的動畫視覺參數
    struct AutoSortAnimationStyle {
        
        let stepDelay: TimeInterval             // 每片拼圖開始移動的延遲時間差（秒），用於營造交錯排開的節奏感
        let duration: TimeInterval              // 單一拼圖移動過程的持續時間（秒）
        let damping: CGFloat                    // 阻尼係數（0.0 ~ 1.0），值越小彈性越強，越接近 1.0 則動畫越平穩無震盪
        let initialVelocity: CGFloat            // 彈簧動畫的初始速度，數值越大起步衝勁越強
        let options: UIView.AnimationOptions    // 動畫選項（如 .curveEaseInOut、.allowUserInteraction 等），定義動畫的過渡曲線與行為
    }
}
