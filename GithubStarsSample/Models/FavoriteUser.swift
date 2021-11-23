//
//  FavoriteUser.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import RealmSwift

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
