//
//  FavoriteService.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import RxCocoa
import RxSwift

enum FavoriteStatus {
    case removed
    case added
}

typealias FavoriteUserInfo = (userId: Int?, status: FavoriteStatus)
protocol FavoriteServiceType {
    
    //변경된 찜유저 정보
    var changedFavoriteUserInfo: PublishRelay<FavoriteUserInfo> { get }
    
    //찜 추가, 제거
    func setFavorite(item: SearchItem) -> Observable<FavoriteStatus>
    func addFavorite(item: SearchItem) -> Observable<Void>
    func removeFavoriteUser(user: FavoriteUser) -> Observable<Void>
 
    //찜 리스트
    func getFavoriteUserList() -> Observable<[FavoriteUser]>
    
    //찜 여부
    func isFavoriteUser(id: Int) -> Bool
}

final class FavoriteService: FavoriteServiceType {
    
    //변경된 찜유저 정보
    var changedFavoriteUserInfo: PublishRelay<FavoriteUserInfo> {
        return _changedFavoriteUserInfo
    }
    
    //변경된 찜유저 정보
    private let _changedFavoriteUserInfo: PublishRelay<FavoriteUserInfo> = PublishRelay()
    
    
    enum FavoriteServiceError: Error {
        case removeFavorieUserFailed
        case addFavoriteUserFailed
    }
       
    private let storage: LocalStorageServiceType
    
    init(localStorageService: LocalStorageServiceType) {
        self.storage = localStorageService
    }
    
    func setFavorite(item: SearchItem) -> Observable<FavoriteStatus> {
        if let id = item.id, let user = getFavoriteUser(id: id) {
            return removeFavoriteUser(user: user)
                .map { .removed }
        } else {
            return addFavorite(item: item)
                .map { .added }
        }
    }
    
    func addFavorite(item: SearchItem) -> Observable<Void> {
        let addedFavoriteUser = FavoriteUser(from: item)
        let isSuccess = storage.write(addedFavoriteUser)
        print("addFavoriteUser isSuccess: \(isSuccess)")
        
        if isSuccess == true {
            let favoriteInfo = FavoriteUserInfo(userId: item.id, status: .added)
            _changedFavoriteUserInfo.accept(favoriteInfo)
        }
        
        return Observable.create { observer in
            if isSuccess {
                observer.onNext(Void())
                observer.onCompleted()
            } else {
                observer.onError(FavoriteServiceError.addFavoriteUserFailed)
            }
            return Disposables.create()
        }
    }
    
    func removeFavoriteUser(user: FavoriteUser) -> Observable<Void> {
        let id = user.id
        let isSuccess = storage.delete(user)
        print("removeFavoriteUser isSuccess: \(isSuccess)")
     
        if isSuccess == true {
            let favoriteInfo = FavoriteUserInfo(userId: id, status: .removed)
            _changedFavoriteUserInfo.accept(favoriteInfo)
        }
        
        return Observable.create { observer in
            if isSuccess {
                observer.onNext(Void())
                observer.onCompleted()
            } else {
                observer.onError(FavoriteServiceError.removeFavorieUserFailed)
            }
            return Disposables.create()
        }
    }
    
    func getFavoriteUserList() -> Observable<[FavoriteUser]> {
        let favoriteUsers: [FavoriteUser] = storage.objects()
        return Observable.just(favoriteUsers)
    }
    
    func isFavoriteUser(id: Int) -> Bool {
        let favoriteUser = getFavoriteUser(id: id)
        return favoriteUser != nil
    }
    
    private func getFavoriteUser(id: Int) -> FavoriteUser? {
        let favoriteUser: FavoriteUser? = storage.object { $0.id == id }
        return favoriteUser
    }
}
