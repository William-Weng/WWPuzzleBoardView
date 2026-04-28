//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit
import WWPuzzleBoardView

final class ViewController: UIViewController {
    
    @IBOutlet weak var puzzleBoardView: WWPuzzleBoardView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var boardState: WWPuzzleBoardView.BoardState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDemo()
    }
    
    @IBAction func shuffleAction(_ sender: UIButton) {
        puzzleBoardView.shuffle()
    }
    
    @IBAction func solveAction(_ sender: UIButton) {
        puzzleBoardView.solve()
    }
    
    @IBAction func autoSortAction(_ sender: UIButton) {
        puzzleBoardView.autoSort()
    }
}

// MARK: - WWPuzzleBoardView.Delegate
extension ViewController: WWPuzzleBoardView.Delegate {
    
    func puzzleBoardView(_ boardView: WWPuzzleBoardView, didUpdate state: WWPuzzleBoardView.BoardState) {
        apply(state)
    }
    
    func puzzleBoardView(_ boardView: WWPuzzleBoardView, didBeginDraggingTileWithID tileID: Int, state: WWPuzzleBoardView.BoardState) {
        apply(state)
    }
    
    func puzzleBoardView(_ boardView: WWPuzzleBoardView, didChangeDraggingTileWithID tileID: Int, targetCellIndex: Int, state: WWPuzzleBoardView.BoardState) {
        apply(state)
    }
    
    func puzzleBoardView(_ boardView: WWPuzzleBoardView, didEndDraggingTileWithID tileID: Int, targetCellIndex: Int, state: WWPuzzleBoardView.BoardState) {
        apply(state)
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 設定範例
    func setupDemo() {
        
        guard let image = previewImageView.image else { return }
        
        puzzleBoardView.delegate = self
        puzzleBoardView.autoSortAnimationStyle = .manualLike
        puzzleBoardView.configure(rows: 3, cols: 3)
        puzzleBoardView.setup(with: image)
        
        guard let state = puzzleBoardView.boardState else { return }
        apply(state)
    }
    
    /// 更新狀態顯示
    /// - Parameter state: WWPuzzleBoardView.BoardState
    func apply(_ state: WWPuzzleBoardView.BoardState) {
        boardState = state
        updateStatusLabel(state)
    }
    
    /// 更新狀態文字
    /// - Parameter state: WWPuzzleBoardView.BoardState
    func updateStatusLabel(_ state: WWPuzzleBoardView.BoardState) {
        statusLabel.text = state.isSolved ? "Completed!" : "\(state.correctCount) / \(state.tiles.count)"
    }
}
