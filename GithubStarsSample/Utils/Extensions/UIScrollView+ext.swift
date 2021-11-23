//
//  UIScrollView+ext.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import UIKit

extension UIScrollView {
    func isNearBottomEdge(edgeOffset: CGFloat = 200) -> Bool {
        return contentOffset.y + frame.size.height + edgeOffset > contentSize.height
    }
}
