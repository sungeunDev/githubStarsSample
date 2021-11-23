//
//  List.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation

/*
{
  "total_count": 12,
  "incomplete_results": false,
  "items": [
   ]
 }
}
*/

struct List<T>: ModelType where T: ModelType {
    let totalCount: Int?
    let incompleteResults: Bool?
    let items: [T]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}


