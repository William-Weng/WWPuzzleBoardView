//
//  Protocol.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import Foundation

public extension WWPuzzleBoardView {
    
    /// WWPuzzleBoardView的動作事件
    protocol Delegate: AnyObject {
        
        /// board 狀態更新後呼叫，適用於 shuffle、solve、auto sort 等一般操作
        func puzzleBoardView(_ boardView: WWPuzzleBoardView, didUpdate state: WWPuzzleBoardView.BoardState)
        
        /// 開始拖曳 tile 時呼叫，回傳更新後的 board state
        func puzzleBoardView(_ boardView: WWPuzzleBoardView, didBeginDraggingTileWithID tileID: Int, state: WWPuzzleBoardView.BoardState)
        
        /// 拖曳過程中呼叫，回傳目前目標格與更新後的 board state
        func puzzleBoardView(_ boardView: WWPuzzleBoardView, didChangeDraggingTileWithID tileID: Int, targetCellIndex: Int, state: WWPuzzleBoardView.BoardState)
        
        /// 結束拖曳時呼叫，回傳最終目標格與更新後的 board state
        func puzzleBoardView(_ boardView: WWPuzzleBoardView, didEndDraggingTileWithID tileID: Int, targetCellIndex: Int, state: WWPuzzleBoardView.BoardState)
    }
}

extension WWPuzzleBoardView {
    
    /// 接收 tile 拖曳生命週期事件的代理
    protocol TileViewDelegate: AnyObject {
        
        /// 當 tile 開始被拖曳時呼叫
        func tileViewDidBeginDragging(_ tileView: TileView)
        
        /// 當 tile 拖曳位置持續變化時呼叫
        func tileViewDidChangeDragging(_ tileView: TileView)
        
        /// 當 tile 結束拖曳時呼叫
        func tileViewDidEndDragging(_ tileView: TileView)
    }
}
