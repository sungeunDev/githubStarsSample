//
//  GlobalStates.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/23.
//


import RxCocoa
import RxSwift

typealias FavoriteUserInfo = (userId: Int?, status: FavoriteStatus)
final class GlobalStates {
    
    static let shared = GlobalStates()
    
    
    
    var changedFavoriteUserInfo: PublishRelay<FavoriteUserInfo> = PublishRelay()
}
