//
//  AppDelegate.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var dependency: AppDependency!
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.dependency = self.dependency ?? CompositionRoot.resolve()
        self.window = self.dependency.window
        return true
    }
}

