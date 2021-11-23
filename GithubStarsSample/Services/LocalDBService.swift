//
//  LocalDBService.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

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
    
    //@discardableResult > ?? 이게뭔지
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
        let isSuccess = storage.delete(user)
        print("removeFavoriteUser isSuccess: \(isSuccess)")
     
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


// MARK: - 찜 관련 매니저
final class FavoriteListManager: NSObject {
    static let shared = FavoriteListManager()
    
    private var disposeBag = DisposeBag()
    
    private override init() { }
    
    func loadFavoriteList() {
        
    }
    
    func setFavorite(placeId: Int, category: Int) {
        
//        //현재 찜리스트에 있는지 여부
//        let hasFavorite: Bool = favoritesDictionary.keys.contains(key)
//
//        //변경된 찜 정보 전달 (api 응답과 관계없이 앱 내부에서 처리)
//        let isFavorite: Bool = !hasFavorite //찜상태 변경
//        changedFavoriteInfoSubject.onNext(FavoriteInfo(item: myFavorite, isFavorite: isFavorite))
        
    }
    
    /// 찜 변경 사항이 있는 숙소 정보 (주로 찜버튼 UI 갱신시 이용)
//    var changedFavoriteInfoSubject: PublishSubject<FavoriteInfo> = PublishSubject()
    
    //전체 찜 리스트
//    var favoritesDictionary: [FavoriteKey: MyFavorite] = [:]
}

