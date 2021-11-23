//
//  GlobalStates.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation
import RxCocoa
import RxSwift

final class GlobalStates {
    
    static let shared = GlobalStates()
    
    // MARK: 찜 리스트 정보
    var favoriteUserList: BehaviorRelay<[FavoriteUser]> = BehaviorRelay(value: [])
    
    // 찜 정보가 변경된 유저 정보
    var changedFavoriteUserData: PublishRelay<(userId: Int, isFavorite: Bool)> = PublishRelay()
}
