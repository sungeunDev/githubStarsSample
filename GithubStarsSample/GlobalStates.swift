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
    
    //변경된 찜유저 정보
    var changedFavoriteUserInfo: PublishRelay<FavoriteUserInfo> = PublishRelay()
}
