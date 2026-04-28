//
//  ImageFactory.swift
//  WWPuzzleBoardView
//
//  Created by William.Weng on 2026/4/27.
//

import UIKit

// MARK: - 產生切片圖片工廠
extension WWPuzzleBoardView {
    
    /// 產生切片圖片素材
    enum ImageFactory {
        
        /// 根據原圖與 tile 定義，建立拼圖所需的影像素材 (tile.sourceRect)
        func makeAsset(from image: UIImage, tiles: [Tile]) throws -> ImageAsset {
            
            let normalized = image.normalized()
            
            guard let cgImage = normalized.cgImage else { throw ImageFactoryError.missingCGImage }
            
            var tileImages: [Int: UIImage] = [:]
            
            for tile in tiles {
                guard let cropped = cgImage.cropping(to: tile.sourceRect) else { throw ImageFactoryError.cropFailed(tile.id) }
                tileImages[tile.id] = UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
            }
            
            return .init(image: normalized, cgImage: cgImage, tileImages: tileImages)
        }
    }
}
