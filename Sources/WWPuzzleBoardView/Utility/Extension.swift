//
//  Extension.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit

// MARK: - UIImage
extension UIImage {
    
    /// 將圖片「實際」轉成 `.up` 方向的 UIImage => UIImage 有時候看起來是正的，其實只是靠 `imageOrientation` 這個 metadata 在顯示時修正方向，底層的像素資料本身不一定真的已經轉正。
    func normalized() -> UIImage {
        
        guard imageOrientation != .up,
              let cgImage = self.cgImage
        else {
            return self
        }
        
        let format: UIGraphicsImageRendererFormat = .default()
        format.scale = self.scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalizeImage = renderer.image { _ in
            UIImage(cgImage: cgImage, scale: scale, orientation: .up).draw(in: .init(origin: .zero, size: size))
        }
        
        return normalizeImage
    }
}
