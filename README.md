# [WWPuzzleBoardView](https://swiftpackageindex.com/William-Weng)

[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![iOS-16.0](https://img.shields.io/badge/iOS-16.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWPuzzleBoardView)
[![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) 
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

## 🎉 [相關說明](https://qoaformat.org/qoa-specification.pdf)
- [A `UIKit-based` puzzle board component that slices a `UIImage` into draggable puzzle tiles, with support for custom rows and columns, shuffling, solving, auto-sort animations, and both Storyboard and code-based initialization.]()
- [一個以 `UIKit` 實作的拼圖看板元件，可以把一張 `UIImage` 切割成可拖曳的拼圖方塊，並支援自訂列數與欄數、打亂、解題、自動排序動畫，以及 Storyboard / 程式碼兩種初始化方式。](https://medium.com/@jqkqq7895/swift-pan-gesture-711e05d435b0)

## 📷 [效果預覽](https://peterpanswift.github.io/iphone-bezels/)

[![](https://github.com/user-attachments/assets/9aff409e-8da1-40ae-aa4c-5c586206a559)](https://freepngimg.com/png/28746-mario-bros-photos)

https://github.com/user-attachments/assets/c39b9124-a85e-47d9-a799-db663f8bd147

<div align="center">

**⭐ 覺得好用就給個 Star 吧！**

</div>

## 💿 [安裝方式](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)

使用 **Swift Package Manager (SPM)**：

```swift
dependencies: [
    .package(url: "https://github.com/William-Weng/WWPuzzleBoardView", .upToNextMinor(from: "1.0.0"))
]
```

## ✨ 功能特色

- 支援任意 `UIImage` 建立拼圖。
- 可自訂 `rows` / `cols`。
- 支援拖曳拼圖方塊交換位置。
- 支援隨機打亂。
- 支援立即解題。
- 支援自動排序動畫。
- 可直接在 Storyboard 使用。
- 提供 delegate 回傳互動與狀態更新事件。

## 🧲 公開函數

| 參數名稱 | 說明 |
|-----------|------|
| `configure(rows:cols:)` | 設定拼圖有幾塊 (rows * cols) |
| `setup(with:mode:)` | 使用原始圖片建立拼圖所需的圖片資源、初始 tile 狀態與初始畫面 |
| `shuffle()` | 打亂目前拼圖位置，並以互動動畫更新畫面 |
| `autoSort()` | 將所有 tile 排回正確位置，並播放完成排序動畫 |
| `solve(animated:)` | 將所有 tile 直接排回正確位置 |

## 🚀 使用範例

```swift
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

private extension ViewController {
    
    func setupDemo() {
        
        guard let image = previewImageView.image else { return }
        
        puzzleBoardView.delegate = self
        puzzleBoardView.autoSortAnimationStyle = .manualLike
        puzzleBoardView.configure(rows: 3, cols: 3)
        puzzleBoardView.setup(with: image)
        
        guard let state = puzzleBoardView.boardState else { return }
        apply(state)
    }
    
    func apply(_ state: WWPuzzleBoardView.BoardState) {
        boardState = state
        updateStatusLabel(state)
    }
    
    func updateStatusLabel(_ state: WWPuzzleBoardView.BoardState) {
        statusLabel.text = state.isSolved ? "Completed!" : "\(state.correctCount) / \(state.tiles.count)"
    }
}
```
