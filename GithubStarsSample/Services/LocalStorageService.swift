//
//  LocalStorageService.swift
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
