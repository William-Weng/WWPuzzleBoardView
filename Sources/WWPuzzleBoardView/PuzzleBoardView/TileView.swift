//
//  TileView.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit

// MARK: - 單一片拼圖的互動視圖
public extension WWPuzzleBoardView {
    
    class TileView: UIView {
        
        public let tileID: Int
        
        weak var boardView: UIView?                             // 參照到父容器，用來做座標轉換與處理層級（bringSubviewToFront）
        weak var delegate: TileViewDelegate?                    // 代理人，用來回報拖曳狀態給外部 board view。
        
        private let contentImageView: UIImageView = .init()     // 用來顯示拼圖內容的影像視圖。
        private let cornerRadius: CGFloat = 8                   // 圓角半徑
        
        private var startCenter: CGPoint = .zero                // 記錄開始拖曳時的中心點，用來計算偏移量。
        
        private(set) var isDragging: Bool = false               // 目前是否正在拖曳中。
        
        /// 初始化
        /// - Parameters:
        ///   - tileID: 這塊拼圖的唯一識別碼
        ///   - image: 拼圖圖片
        public init(tileID: Int, image: UIImage) {
            self.tileID = tileID
            super.init(frame: .zero)
            
            setupUI()
            setupContentImageView(image)
            setupGestureRecognizer()
        }
        
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            drawShadowPath()
        }
    }
}

// MARK: - 視覺樣式設定
extension WWPuzzleBoardView.TileView {
    
    /// 設定拖曳時的視覺樣式（放大、微透明）
    func applyDraggingStyle() {
        
        isDragging = true
        
        let changes = {
            self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            self.alpha = 0.97
            self.layer.shadowOpacity = 0.22
            self.layer.shadowRadius = 12
            self.layer.shadowOffset = CGSize(width: 0, height: 8)
        }
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.12, delay: 0) { changes() }
    }
    
    /// 重置為正常狀態
    func resetVisualStyle(animated: Bool) {
        
        isDragging = false
        
        let changes = {
            self.transform = .identity
            self.alpha = 1.0
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.10
            self.layer.shadowRadius = 6
            self.layer.shadowOffset = CGSize(width: 0, height: 3)
        }
        
        if (!animated) { changes(); return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.15, delay: 0) { changes() }
    }
    
    /// 切換目標高亮顯示（通常用於自動排序或吸附判定）=> 會改變陰影的強度、顏色，並縮小圖塊（縮小效果讓高亮更聚焦）=> 如果沒在拖曳才縮放，避免與拖曳效果衝突
    func setTargetHighlighted(_ highlighted: Bool, animated: Bool) {
        
        let changes = {
            
            self.layer.shadowColor = (highlighted ? UIColor.systemBlue : UIColor.black).cgColor
            self.layer.shadowOpacity = highlighted ? 0.28 : 0.10
            self.layer.shadowRadius = highlighted ? 14 : 6
            self.layer.shadowOffset = highlighted ? CGSize(width: 0, height: 8) : CGSize(width: 0, height: 3)
            self.alpha = highlighted ? 0.45 : 1.0
            
            if (!self.isDragging) { self.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity }
        }
        
        if (!animated) { changes(); return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.12, delay: 0, options: [.curveEaseOut]) { changes() }
    }
}

// MARK: - 手勢處理
private extension WWPuzzleBoardView.TileView {
    
    /// 處理拖曳手勢
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        guard let boardView else { return }
        
        switch gesture.state {
        case .began: beginDragging(in: boardView)
        case .changed: updateDragging(with: gesture, in: boardView)
        case .ended, .cancelled: endDragging()
        default: break
        }
    }
    
    /// 處理狀態 .began: 記錄位置、把圖層拉到最上層、觸發開始拖曳通知。
    func beginDragging(in boardView: UIView) {
        
        startCenter = center
        boardView.bringSubviewToFront(self)
        delegate?.tileViewDidBeginDragging(self)
    }
    
    /// 處理狀態 .changed: 計算新位置並限制在 board 範圍內，通知移動。
    func updateDragging(with gesture: UIPanGestureRecognizer, in boardView: UIView) {
        
        let translation = gesture.translation(in: boardView)
        
        var newCenter = CGPoint(x: startCenter.x + translation.x, y: startCenter.y + translation.y)
        
        let halfW = bounds.width * 0.5
        let halfH = bounds.height * 0.5
        
        newCenter.x = min(max(newCenter.x, halfW), boardView.bounds.width - halfW)
        newCenter.y = min(max(newCenter.y, halfH), boardView.bounds.height - halfH)
        
        center = newCenter
        delegate?.tileViewDidChangeDragging(self)
    }
    
    /// 處理狀態 .ended/cancelled: 通知結束拖曳，讓 board 決定是否要吸附或交換。
    func endDragging() {
        delegate?.tileViewDidEndDragging(self)
    }
}

// MARK: - 初始化設定
private extension WWPuzzleBoardView.TileView {
    
    /// 加入淡淡邊框增加拼圖塊的邊緣質感
    func setupContentImageView(_ image: UIImage) {
        
        contentImageView.image = image
        contentImageView.contentMode = .scaleToFill
        contentImageView.clipsToBounds = true
        
        contentImageView.layer.cornerRadius = cornerRadius
        contentImageView.layer.borderWidth = 0.5
        contentImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.20).cgColor
        
        addSubview(contentImageView)
    }
    
    /// 設定Layer層 => 必須設為 clipsToBounds = false，陰影才不會被剪掉
    func setupUI() {

        isUserInteractionEnabled = true
        backgroundColor = .clear
        clipsToBounds = false
        
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    
    /// 加入拖曳手勢
    func setupGestureRecognizer() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    /// 設定陰影路徑以最佳化渲染效能 => 透過 `shadowPath`，系統不需要即時計算複雜的透明層陰影，直接繪製指定形狀即可。
    func drawShadowPath() {
        contentImageView.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
}
