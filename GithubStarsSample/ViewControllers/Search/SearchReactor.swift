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
    
    typealias RequestResult = (list: List<SearchItem>, nextPage: Int?)
    
    enum Action {
        case searchUserName(name: String)
        case loadMore
        case clickFavoriteButton(item: SearchItem)
    }
    
    enum Mutation {
        case setSearchKeyword(String?)
        case setSearchList(RequestResult)
        case appendSearchList(RequestResult)
        case setLoadingNextPage(Bool) //페이징 가능 여부 처리
        case setError(Error)
        case setFavoriteStatus(FavoriteStatus?)
    }
    
    struct State {
        var seachKeyword: String?
        var searchItems: [SearchItem] //검색 아이템
        var error: Error?
        
        //찜 누른 상태
        var favoriteStatus: FavoriteStatus?
        
        //페이징
        var nextPage: Int?
        var isLoadingNextPage: Bool = false //다음 페이지 로딩 여부
    }
    
    var initialState: State
    
    private let searchService: SearchServiceType
    let favoriteService: FavoriteServiceType
    
    init(searchService: SearchServiceType,
         favoriteService: FavoriteServiceType) {
        self.searchService = searchService
        self.favoriteService = favoriteService
        
        initialState = State(searchItems: [])
    }

    // MARK: Mutation
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .searchUserName(let keyword):
            let setKeyword = Observable.just(Mutation.setSearchKeyword(keyword))
            let loadList = searchUserList(name: keyword, page: 1)
                .map { Mutation.setSearchList($0) }
                .catchError { Observable.just(Mutation.setError($0)) }
            return .concat(setKeyword, loadList)
            
        case .loadMore:
            guard let keyword = currentState.seachKeyword,
                  currentState.isLoadingNextPage == false,
                  let page = currentState.nextPage else {
                return Observable.empty()
            }
            
            //다음 페이지 리퀘스트 더이상 안되도록 처리
            let loadingNextPage = Observable.just(Mutation.setLoadingNextPage(true))
            
            let loadList = searchUserList(name: keyword, page: page)
                .map { Mutation.appendSearchList($0) }
                .catchError { Observable.just(Mutation.setError($0)) }
            
            let resetLoadingNextPage = Observable.just(Mutation.setLoadingNextPage(false))
            
            return .concat([ loadingNextPage, loadList, resetLoadingNextPage ])
            
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
        case .setSearchKeyword(let keyword):
            newState.seachKeyword = keyword
            
        case .setSearchList(let result):
            newState.searchItems = result.list.items
            newState.nextPage = result.nextPage
            
        case .appendSearchList(let result):
            var newList = currentState.searchItems
            let addedItems = result.list.items
            newList.append(contentsOf: addedItems)
            
            newState.searchItems = newList
            newState.nextPage = result.nextPage
            
        case .setError(let error):
            newState.error = error
            
        case .setFavoriteStatus(let status):
            newState.favoriteStatus = status
            
        case .setLoadingNextPage(let isLoadingNextPage):
            newState.isLoadingNextPage = isLoadingNextPage
            
        }
        
        return newState
    }
    
    //support
    func isFavoriteItem(item: SearchItem) -> Bool {
        guard let id = item.id else { return false }
        return favoriteService.isFavoriteUser(id: id)
    }
    
    //request
    private func searchUserList(name: String, page: Int) -> Observable<RequestResult> {
        let perPageCount: Int = 20

        return searchService.userList(name: name, page: page, perPageCount: perPageCount)
            .map { list in
                var nextPage: Int? {
                    if let totalCount = list.totalCount, Int(totalCount / perPageCount) >= page {
                        return page + 1
                    } else {
                        return nil
                    }
                }
                return (list, nextPage)
            }
    }
}
