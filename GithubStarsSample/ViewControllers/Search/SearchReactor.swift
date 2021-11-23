//
//  SearchReactor.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import ReactorKit
import RxCocoa
import RxSwift

class SearchReactor: Reactor {
    
    enum Action {
        case searchUserName(name: String)
        case loadMore(page: Int)
        case clickFavoriteButton(item: SearchItem)
    }
    
    enum Mutation {
        case setSearchList(List<SearchItem>)
        case setError(Error)
        
        case setFavoriteStatus(FavoriteStatus?)
    }
    
    struct State {
        var isLoading: Bool = false
        
        var isRefreshing: Bool = false
        var searchItems: [SearchItem]
        
        var error: Error?
        
        var favoriteStatus: FavoriteStatus?
    }
    
    
    var initialState: State
    
    private let searchService: SearchServiceType
    private let favoriteService: FavoriteServiceType
    
    init(searchService: SearchServiceType,
         favoriteService: FavoriteServiceType) {
        self.searchService = searchService
        self.favoriteService = favoriteService
        
        initialState = State(searchItems: [])
    }

    // MARK: Mutation
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .searchUserName(let name):
            return searchService.userList(name: name, page: 1)
                .map { Mutation.setSearchList($0) }
                .catchError { Observable.just(Mutation.setError($0)) }
            
        case .loadMore(let page):
            return .empty()
            
        case .clickFavoriteButton(let item):
            let setFavorite = favoriteService.setFavorite(item: item)
                .map { Mutation.setFavoriteStatus($0) }
                .catchError { Observable.just(Mutation.setError($0)) }
            
            let resetFavoriteStatus = Observable.just(Mutation.setFavoriteStatus(nil))
            return .concat(setFavorite, resetFavoriteStatus)
        }
    }
    
    // MARK: Reduce
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.error = nil
        
        switch mutation {
        case .setSearchList(let list):
            newState.searchItems = list.items
        case .setError(let error):
            newState.error = error
            
        case .setFavoriteStatus(let status):
            newState.favoriteStatus = status
        }
        
        return newState
    }
}
