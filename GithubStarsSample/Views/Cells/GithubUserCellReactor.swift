//
//  GithubUserCellReactor.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import ReactorKit

final class GithubUserCellReactor: Reactor {
    
    enum Action {
        case changeFavoriteStatus(FavoriteStatus)
    }
    
    enum Mutation {
        case setIsFavorite(Bool)
    }
    
    struct State {
        let userName: String?
        let imagePath: String?
        var isFavorite: Bool
    }
    
    var initialState: State
    
    init(userName: String?, imagePath: String?, isFavorite: Bool) {
        initialState = State(userName: userName, imagePath: imagePath, isFavorite: isFavorite)
    }
    
    // MARK: Mutation
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .changeFavoriteStatus(let status):
            let isFavorite = status == .added
            return .just(Mutation.setIsFavorite(isFavorite))
        }
    }
    
    // MARK: Reduce
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setIsFavorite(let isFavorite):
            newState.isFavorite = isFavorite
        }
        return newState
    }
}
