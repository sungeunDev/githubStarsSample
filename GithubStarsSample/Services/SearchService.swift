//
//  SearchService.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Alamofire
import RxSwift


protocol SearchServiceType {
    func userList(name: String, page: Int) -> Observable<List<SearchItem>>
}

final class SearchService: SearchServiceType {
    
    private let networking: SearchNetworking
    
    init(networking: SearchNetworking) {
        self.networking = networking
    }
    
    func userList(name: String, page: Int) -> Observable<List<SearchItem>> {
        return self.networking.request(.searchUserList(name: name, page: page))
//            .debug()
            .asObservable()
            .map(List<SearchItem>.self)
    }
}
