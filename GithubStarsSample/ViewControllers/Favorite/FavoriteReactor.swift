//
//  FavoriteReactor.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/22.
//

import ReactorKit
import RxCocoa
import RxSwift

class FavoriteReactor: Reactor {
    
    enum Action {
        case loadFavoriteUsers
        case removeFavoriteUser(user: FavoriteUser)
        
        case searchFavoriteUser(keyword: String)
        case resetSearchResult
    }
    
    enum Mutation {
        case setFavoriteUserList([FavoriteUser])
        case setError(Error?)
        
        case setIsSuccessRemoveFavoriteUser(Bool)
        
//        case setSearchedFavoriteUser([FavoriteUser])
    }
    
    struct State {
        var favoriteUsers: [FavoriteUser] = []
//        var searchedFavoriteUsers: [FavoriteUser] = []
        
        var error: Error?
        
        var isRemoveFavoriteUser: Bool = false
    }
    
    
    var initialState: State
    
    private let favoriteService: FavoriteServiceType
    
    
    init(favoriteService: FavoriteServiceType) {
        self.favoriteService = favoriteService
        
        initialState = State()
    }

    // MARK: Mutation
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        
        case .loadFavoriteUsers, .resetSearchResult:
            return getFavoriteUsers()
                .map { Mutation.setFavoriteUserList($0) }
            
        case .removeFavoriteUser(let user):
            let setSuccessRemoveUser = favoriteService.removeFavoriteUser(user: user)
                .map { Mutation.setIsSuccessRemoveFavoriteUser(true) }
                .catchError { error in
                    Observable.just(Mutation.setError(error))
                }
            
            let getUserList = getFavoriteUsers()
                .map { Mutation.setFavoriteUserList($0) }
            
            let resetSuccessRemoveUser = Observable.just(Mutation.setIsSuccessRemoveFavoriteUser(false))
            
            return Observable.concat([ setSuccessRemoveUser, getUserList, resetSuccessRemoveUser ])
            
        case .searchFavoriteUser(let keyword):
            
            let searchResult = currentState.favoriteUsers
                .filter { $0.userId?.contains(keyword) ?? false }
                
            return Observable.just(Mutation.setFavoriteUserList(searchResult))

        }
    }
    
    // MARK: Reduce
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.error = nil
        
        switch mutation {
        case .setFavoriteUserList(let list):
            newState.favoriteUsers = list
            
        case .setError(let error):
            newState.error = error

        case .setIsSuccessRemoveFavoriteUser(let isSuccess):
            newState.isRemoveFavoriteUser = isSuccess
        }
        return newState
    }
    
    //support methods
    private func getFavoriteUsers() -> Observable<[FavoriteUser]> {
        return favoriteService.getFavoriteUserList()
    }
}
