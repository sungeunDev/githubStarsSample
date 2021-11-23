//
//  LocalDBService.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import RxCocoa
import RxSwift
import Realm
import RealmSwift

protocol LocalStorageServiceType {
    func object<T: Object>() -> T?
    func object<T: Object>(_ key: Any?) -> T?
    func object<T: Object>(_ predicate: (T) -> Bool) -> T?
    
    func objects<T: Object>() -> [T]
    func objects<T: Object>(_ predicate: (T) -> Bool) -> [T]
    
    @discardableResult func write<T: Object>(_ object: T?) -> Bool
    @discardableResult func write<T: Object>(_ objects: [T]?) -> Bool
    
    @discardableResult func update(_ block: () -> ()) -> Bool
    @discardableResult func delete<T: Object>(_ object: T) -> Bool
}

typealias LocalStorage = Realm
class LocalStorageService: LocalStorageServiceType {
    
    var localStorage: LocalStorage
    
    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }
    
    func object<T: Object>() -> T? {
        let key: AnyObject = 0 as AnyObject
        return self.object(key)
    }
    
    func object<T: Object>(_ key: Any?) -> T? {
        guard let key: Any = key else { return nil }
        
        guard let object: T = localStorage.object(ofType: T.self, forPrimaryKey: key) else { return nil }
        return !object.isInvalidated ? object : nil
    }
    
    func object<T: Object>(_ predicate: (T) -> Bool) -> T? {
        
        return localStorage.objects(T.self).filter(predicate).filter({ !$0.isInvalidated }).first
    }
    
    func objects<T: Object>() -> [T] {
        
        return localStorage.objects(T.self).filter({ !$0.isInvalidated })
    }
    
    func objects<T: Object>(_ predicate: (T) -> Bool) -> [T] {
        
        return localStorage.objects(T.self).filter(predicate).filter({ !$0.isInvalidated })
    }
    
    func write<T: Object>(_ object: T?) -> Bool {
        guard let object: T = object else { return false }
        
        guard !object.isInvalidated else { return false }
        
        do {
            try localStorage.write {
                localStorage.add(object, update: Realm.UpdatePolicy.all)
            }
            return true
        } catch let error {
            print("Writing failed for ", String(describing: T.self), " with error ", error)
        }
        return false
    }
    
    
    func write<T: Object>(_ objects: [T]?) -> Bool {
        guard let objects: [T] = objects else { return false }
        
        let validated: [T] = objects.filter({ !$0.isInvalidated }) //유효성 체크
        do {
            try localStorage.write {
                localStorage.add(validated, update: Realm.UpdatePolicy.all)
            }
            return true
        } catch let error {
            print("Writing of array failed for ", String(describing: T.self), " with error ", error)
        }
        return false
    }
    
    func update(_ block: (() -> Void)) -> Bool {
        
        do {
            try localStorage.write(block)
            return true
        } catch let error {
            print("Updating failed with error ", error)
        }
        return false
    }
    
    func delete<T: Object>(_ object: T) -> Bool {
        
        guard !object.isInvalidated else { return true }
        do {
            try localStorage.write {
                localStorage.delete(object)
            }
            return true
        } catch let error {
            print("Writing of array failed for ", String(describing: T.self), " with error ", error)
        }
        return false
    }
    
}


class FavoriteUser: Object {
    @objc dynamic var userId: String?
    @objc dynamic var id: Int = 0
    @objc dynamic var avartarUrl: String?
    @objc dynamic var url: String?
    @objc dynamic var htmlUrl: String?
    @objc dynamic var reposUrl: String?
    @objc dynamic var score: Int = 0
    @objc dynamic var createdDateAt: Date = Date()
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override init() {
        
    }
    
    convenience init(userId: String?, id: Int, avartarUrl: String?, url: String?, htmlUrl: String?, reposUrl: String?, score: Int) {
        self.init()
        
        self.userId = userId
        self.id = id
        self.avartarUrl = avartarUrl
        self.url = url
        self.htmlUrl = htmlUrl
        self.reposUrl = reposUrl
        self.score = score
    }
    
    convenience init(from searchItem: SearchItem) {
        let id = searchItem.id ?? 0
        let score = searchItem.score ?? 0
        self.init(userId: searchItem.login, id: id, avartarUrl: searchItem.avartarUrl, url: searchItem.url, htmlUrl: searchItem.htmlUrl, reposUrl: searchItem.reposUrl, score: score)
    }
}

enum FavoriteStatus {
    case removed
    case added
}

protocol FavoriteServiceType {
    
    var favoriteUserList: [FavoriteUser] { get }
    
    func setFavorite(item: SearchItem) -> Observable<FavoriteStatus>
    
    func addFavorite(item: SearchItem) -> Observable<Void>
    func removeFavoriteUser(user: FavoriteUser) -> Observable<Void>
 
    func getFavoriteUserList() -> Observable<[FavoriteUser]>
    func getFavoriteList() -> [FavoriteUser]
    func isFavoriteUser(id: Int) -> Bool
}

final class FavoriteService: FavoriteServiceType {
    
    enum FavoriteServiceError: Error {
        case removeFavorieUserFailed
        case addFavoriteUserFailed
    }
       
    private let storage: LocalStorageServiceType
    
    var favoriteUserList: [FavoriteUser] {
        return getFavoriteList()
    }
    
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
            GlobalStates.shared.changedFavoriteUserInfo.accept(FavoriteUserInfo(userId: item.id, status: .added))
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
            GlobalStates.shared.changedFavoriteUserInfo.accept(FavoriteUserInfo(userId: id, status: .removed))
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
    
    func getFavoriteList() -> [FavoriteUser] {
        let favoriteUsers: [FavoriteUser] = storage.objects()
        return favoriteUsers
    }
    
    func getFavoriteUserList() -> Observable<[FavoriteUser]> {
        let favoriteUsers: [FavoriteUser] = storage.objects()
        return Observable.just(favoriteUsers)
    }
    
    func isFavoriteUser(id: Int) -> Bool {
        let favoriteUser = getFavoriteUser(id: id)
        return favoriteUser != nil
    }
    
    func getFavoriteUser(id: Int) -> FavoriteUser? {
        let favoriteUser: FavoriteUser? = storage.object { $0.id == id }
        return favoriteUser
    }
}


