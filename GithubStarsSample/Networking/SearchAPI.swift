//
//  SearchAPI.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Moya

enum SearchAPI {
    // 사용자 이름 검색
    case searchUserList(name: String, page: Int)
}

extension SearchAPI: TargetType {
    var baseURL: URL {
        return URL(string: Constants.URLs.baseURL)!
    }
    
    var path: String {
        switch self {
        case .searchUserList:
            return "/search/users"
        }
    }
    
    var method: Method {
        switch self {
        case .searchUserList:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .searchUserList(let userName, let page):
            let params: [String: Any] = [
                "q": userName,
                "page": page
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return [
            "accept": "application/vnd.github.v3+json"
        ]
    }
}


//{
//  "total_count": 12,
//  "incomplete_results": false,
//  "items": [
//    {
//      "login": "mojombo",
//      "id": 1,
//      "node_id": "MDQ6VXNlcjE=",
//      "avatar_url": "https://secure.gravatar.com/avatar/25c7c18223fb42a4c6ae1c8db6f50f9b?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png",
//      "gravatar_id": "",
//      "url": "https://api.github.com/users/mojombo",
//      "html_url": "https://github.com/mojombo",
//      "followers_url": "https://api.github.com/users/mojombo/followers",
//      "subscriptions_url": "https://api.github.com/users/mojombo/subscriptions",
//      "organizations_url": "https://api.github.com/users/mojombo/orgs",
//      "repos_url": "https://api.github.com/users/mojombo/repos",
//      "received_events_url": "https://api.github.com/users/mojombo/received_events",
//      "type": "User",
//      "score": 1,
//      "following_url": "https://api.github.com/users/mojombo/following{/other_user}",
//      "gists_url": "https://api.github.com/users/mojombo/gists{/gist_id}",
//      "starred_url": "https://api.github.com/users/mojombo/starred{/owner}{/repo}",
//      "events_url": "https://api.github.com/users/mojombo/events{/privacy}",
//      "site_admin": true
//    }
//  ]
//}


//Not modified
//Status: 304 Not Modified
//Validation failed
//Status: 422 Unprocessable Entity
//Service unavailable
//Status: 503 Service Unavailable
