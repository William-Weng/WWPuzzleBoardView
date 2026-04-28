//
//  Constant.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit

// MARK: - 公開enum
public extension WWPuzzleBoardView {
    
    /// 定義拼圖看板的渲染與動畫執行模式
    enum RenderMode {
        
        case instant                                                // 瞬間完成：所有拼圖直接跳轉至目標位置，無任何動畫，適合初始化或快速重置
        case interactive                                            // 互動模式：響應玩家的操作（如拖曳），動畫表現較為流暢，重視即時回饋感
        case solvedSequence                                         // 完成序列：以演示模式執行自動排序，適合「拼圖完成」或「自動解題」後的展示流程
    }
    
    /// 自動排序動畫的預設風格設定
    enum AnimationStyle {
        
        case snappy                                                 // 快速且利落的動態效果，適合一般整理操作
        case manualLike                                             // 節奏較緩慢，模擬人工拖曳時的儀式感
        case demo                                                   // 節奏最慢，適合用於教學或展示引導
    }
}

// MARK: - enum
extension WWPuzzleBoardView {
    
    /// 拼圖看板的事件，用來回傳拖曳過程與盤面操作結果
    enum BoardEvent {
        
        case didBeginDragging(tileID: Int)                          // 開始拖曳某個 tile。
        case didChangeDragging(tileID: Int, targetCellIndex: Int)   // 拖曳中，且目前滑過或對應到某個目標格子
        case didEndDragging(tileID: Int, targetCellIndex: Int)      // 結束拖曳，並完成 tile 交換或位置更新
        case didShuffle                                             // 拼圖被打亂
        case didSolve                                               // 拼圖被直接解回完成狀態
        case didAutoSort                                            // 拼圖透過自動排序動畫回到完成狀態
    }
    
    /// 圖片產生錯誤
    enum ImageFactoryError: Error {
        
        case missingCGImage                                         // 無法從 UIImage 取得底層的 CGImage
        case cropFailed(Int)                                        // 某一塊 tile 的裁切失敗。參數 Int 通常用來記錄失敗的 tile id 或 index，方便除錯時知道是哪一塊出問題
    }
    
    /// 定義 board 使用的統一動畫風格
    enum BoardAnimationStyle {
        
        case instant                                                                                                                    // 立即套用，不執行動畫
        case quick                                                                                                                      // 短時間快速過渡，適合 reset、highlight 還原這類小幅視覺變化
        case interactive(duration: TimeInterval = 0.25)                                                                                 // 一般互動動畫，使用 ease-out 曲線
        case spring(duration: TimeInterval = 0.42, dampingRatio: CGFloat = 0.78, initialVelocity: CGVector = .init(dx: 0.40, dy: 0.40)) // 彈簧動畫，適合拖曳放手、吸附、交換等需要回彈感的效果
    }
}

// MARK: - AnimationStyle
extension WWPuzzleBoardView.AnimationStyle {
    
    /// 根據選擇的風格回傳對應的動畫參數設定
    func setting() -> WWPuzzleBoardView.AutoSortAnimationStyle {
        
        switch self {
        case .snappy: return .init(stepDelay: 0.04, duration: 0.30, damping: 0.82, initialVelocity: 0.25, options: [.curveEaseInOut, .allowUserInteraction])
        case .manualLike: return .init(stepDelay: 0.18, duration: 0.34, damping: 0.88, initialVelocity: 0.18, options: [.curveEaseInOut, .allowUserInteraction])
        case .demo: return .init(stepDelay: 0.50, duration: 0.32, damping: 0.82, initialVelocity: 0.25, options: [.curveEaseInOut, .allowUserInteraction])
        }
    }
}

// MARK: - BoardAnimationStyle
extension WWPuzzleBoardView.BoardAnimationStyle {
    
    /// 根據指定的動畫風格執行對應的動畫流程，並在需要時回傳 animator 供外部控制
    /// - Parameters:
    ///   - animations: 動畫期間要套用的屬性變化
    ///   - completion: 動畫結束後呼叫的完成回呼，會帶入最終的動畫結束位置
    /// - Returns: 若有建立動畫控制器則回傳 `UIViewPropertyAnimator`；若為立即套用模式則回傳 `nil`
    @discardableResult
    func performAnimation(animations: @escaping () -> Void, completion: ((UIViewAnimatingPosition) -> Void)? = nil) -> UIViewPropertyAnimator? {
        
        switch self {
        case .instant: return instantAnimation(animations: animations, completion: completion)
        case .quick: return quickAnimation(animations: animations, completion: completion)
        case .interactive(let duration): return interactiveAnimation(duration: duration, animations: animations, completion: completion)
        case .spring(let duration, let dampingRatio, let initialVelocity): return springAnimation(duration: duration, dampingRatio: dampingRatio, initialVelocity: initialVelocity, animations: animations, completion: completion)
        }
    }
}

// MARK: - BoardAnimationStyle
private extension WWPuzzleBoardView.BoardAnimationStyle {
    
    /// 立即套用畫面變化，不建立動畫物件，適合初始化或同步狀態
    /// - Parameters:
    ///   - animations: 要立即套用的屬性變化
    ///   - completion: 套用完成後立即呼叫的完成回呼
    /// - Returns: 永遠回傳 `nil`
    func instantAnimation(animations: @escaping () -> Void, completion: ((UIViewAnimatingPosition) -> Void)?) -> UIViewPropertyAnimator? {
        
        animations()
        completion?(.end)
        
        return nil
    }
    
    /// 執行短時間的快速過渡動畫，適合視覺還原、狀態切換或輕量提示效果
    /// - Parameters:
    ///   - animations: 動畫期間要套用的屬性變化
    ///   - completion: 動畫完成後呼叫的完成回呼
    /// - Returns: 由 `runningPropertyAnimator` 建立並立即啟動的 animator
    func quickAnimation(animations: @escaping () -> Void, completion: ((UIViewAnimatingPosition) -> Void)?) -> UIViewPropertyAnimator? {
        
        let animator = UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                animations()
            },
            completion: completion
        )
        
        return animator
    }

    /// 執行一般互動型動畫，使用 ease-out 曲線讓移動與過渡更自然
    /// - Parameters:
    ///   - duration: 動畫持續時間
    ///   - animations: 動畫期間要套用的屬性變化
    ///   - completion: 動畫完成後呼叫的完成回呼
    /// - Returns: 已建立並開始執行的 animator
    func interactiveAnimation(duration: TimeInterval, animations: @escaping () -> Void, completion: ((UIViewAnimatingPosition) -> Void)?) -> UIViewPropertyAnimator? {
        
        let animator = UIViewPropertyAnimator( duration: duration, timingParameters: UICubicTimingParameters(animationCurve: .easeOut))
        animator.addAnimations { animations() }
        
        if let completion { animator.addCompletion(completion) }
        animator.startAnimation()
        
        return animator
    }
    
    /// 執行彈簧動畫，適合吸附、交換、放手回位等需要回彈感的互動效果
    /// - Parameters:
    ///   - duration: 動畫持續時間
    ///   - dampingRatio: 阻尼係數，值越大回彈越少、越穩定
    ///   - initialVelocity: 動畫開始時的初始速度向量
    ///   - animations: 動畫期間要套用的屬性變化
    ///   - completion: 動畫完成後呼叫的完成回呼
    /// - Returns: 已建立並開始執行的 animator
    func springAnimation(duration: TimeInterval, dampingRatio: CGFloat, initialVelocity: CGVector, animations: @escaping () -> Void, completion: ((UIViewAnimatingPosition) -> Void)?) -> UIViewPropertyAnimator? {
        
        let timingParameters = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: initialVelocity)
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)
        
        animator.addAnimations { animations() }
        
        if let completion { animator.addCompletion(completion) }
        animator.startAnimation()
        
        return animator
    }
}
