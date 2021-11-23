//
//  Array+ext.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import Foundation

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
