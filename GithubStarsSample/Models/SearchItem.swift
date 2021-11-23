//
//  SearchItem.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation

// 검색 결과 아이템
struct SearchItem: ModelType, Equatable {
    
    let login: String?
    let id: Int?
    let avartarUrl: String?
    let url: String?
    let htmlUrl: String?
    let reposUrl: String?
    let score: Int?
    
    enum CodingKeys: String, CodingKey {
        case login, id, url, score
        case avartarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case reposUrl = "repos_url"
    }
}
