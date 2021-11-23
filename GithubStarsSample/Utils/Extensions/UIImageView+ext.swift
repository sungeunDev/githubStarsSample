//
//  UIImageView+ext.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/23.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    func setImage(path: String,
                  placeHolder: UIImage? = nil,
                  cornerRadius: CGFloat = 0,
                  fadeTransition: TimeInterval = 0.3,
                  completion: ((Error?) -> Void)? = nil) {
        
        let url = URL(string: path)
        var processor: ImageProcessor {
            if cornerRadius == 0 {
                return DownsamplingImageProcessor(size: self.frame.size)
            } else {
                return DownsamplingImageProcessor(size: self.frame.size)
                |> RoundCornerImageProcessor(cornerRadius: cornerRadius)
            }
        }
        
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(fadeTransition)),
            .cacheOriginalImage
        ]
        
        // 캐시 체크
        let imageCache = KingfisherManager.shared.cache
        let cacheKey = url?.absoluteString ?? ""
        imageCache.retrieveImage(forKey: cacheKey, options: options) { [weak self] result in
            switch result {
            case .success(let value):
                if let image = value.image {
                    self?.image = image
                } else {
                    self?.loadImage(url: url, placeHolder: placeHolder, options: options, completion: completion)
                }
            case .failure:
                imageCache.removeImage(forKey: cacheKey)
                KingfisherManager.shared.cache.cleanExpiredMemoryCache()
                self?.loadImage(url: url, placeHolder: placeHolder, options: options, completion: completion)
            }
        }
    }
    
    private func loadImage(url: URL?,
                           placeHolder: UIImage? = nil,
                           options: KingfisherOptionsInfo,
                           completion: ((Error?) -> Void)? = nil) {
        kf.indicatorType = .activity
        kf.setImage(
            with: url,
            placeholder: placeHolder,
            options: options,
            completionHandler: { (result) in
                switch result {
                case .success:
                    completion?(nil)
                case .failure(let error):
                    completion?(error)
                }
            })
    }
}

