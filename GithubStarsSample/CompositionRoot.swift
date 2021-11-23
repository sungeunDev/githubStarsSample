//
//  CompositionRoot.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation
import Pure
import UIKit

struct AppDependency {
    let window: UIWindow
}

final class CompositionRoot {
    
    static func resolve() -> AppDependency {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.makeKeyAndVisible()
     
        if let localStorage = getLocalStorage() {
            print("----------- <\(#file), \(#function), \(#line)> -----------")
            let localStorageService = LocalStorageService(localStorage: localStorage)
            let favoriteService = FavoriteService(localStorageService: localStorageService)
            
            let searchNetworking = SearchNetworking()
            let searchService = SearchService(networking: searchNetworking)
            let searchReactor = SearchReactor(searchService: searchService,
                                              favoriteService: favoriteService)
            let searchController = SearchViewController(reactor: searchReactor)
            
            let favoriteReactor = FavoriteReactor(favoriteService: favoriteService)
            let favoriteController = FavoriteViewController(reactor: favoriteReactor)
            
            let mainController = MainViewController(searchViewController: searchController,
                                                    favoriteViewController: favoriteController)
            
            window.rootViewController = UINavigationController(rootViewController: mainController)
        } else {
            //load local storage error page
            print("----------- <\(#file), \(#function), \(#line)> -----------")
        }
        
        return AppDependency(window: window)
    }
    
    static func getLocalStorage() -> LocalStorage? {
        var localStorage: LocalStorage? {
            do {
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                return try LocalStorage()
            } catch let error {
                print("localStorage init failed: ", error.localizedDescription)
                return nil
            }
        }
        print("----------- <\(#file), \(#function), \(#line)> -----------")
        return localStorage
    }
}
