//
//  FavoriteReactor.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/22.
//

import ReactorKit
import RxCocoa
import RxSwift
import Realm

class FavoriteReactor: Reactor {
    
    enum Action {
        case loadFavoriteUsers
        case removeFavoriteUser(user: FavoriteUser)
        case searchFavoriteUser(keyword: String)
    }
    
    enum Mutation {
        case setFavoriteUserList([FavoriteUser])
        case setError(Error?)
        case setIsSuccessRemoveFavoriteUser(Bool)
    }
    
    struct State {
        var favoriteUsers: [FavoriteUser] = []
        var error: Error?
        var isRemoveFavoriteUser: Bool = false
    }
    
    
    var initialState: State
    let favoriteService: FavoriteServiceType
    
    init(favoriteService: FavoriteServiceType) {
        self.favoriteService = favoriteService
        
        initialState = State()
    }

    // MARK: Mutation
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        
        case .loadFavoriteUsers:
            return getFavoriteUsers()
                .map { Mutation.setFavoriteUserList($0) }
            
        case .removeFavoriteUser(let user):
            let setSuccessRemoveUser = favoriteService.removeFavoriteUser(user: user)
                .map { Mutation.setIsSuccessRemoveFavoriteUser(true) }
                .catchError { error in
                    Observable.just(Mutation.setError(error))
                }
            
            let resetSuccessRemoveUser = Observable.just(Mutation.setIsSuccessRemoveFavoriteUser(false))
            
            return Observable.concat([ setSuccessRemoveUser, resetSuccessRemoveUser ])
            
        case .searchFavoriteUser(let keyword):
            let lowercasedKeyword = keyword.lowercased()
            let searchResult = currentState.favoriteUsers
                .filter { $0.userId?.contains(lowercasedKeyword) ?? false }
            
            return Observable.just(Mutation.setFavoriteUserList(searchResult))
        }
    }
    
    // MARK: Reduce
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.error = nil
        
        switch mutation {
        case .setFavoriteUserList(let list):
            newState.favoriteUsers = list
            
        case .setError(let error):
            newState.error = error

        case .setIsSuccessRemoveFavoriteUser(let isSuccess):
            newState.isRemoveFavoriteUser = isSuccess
        }
        return newState
    }
    
    //support methods
    private func getFavoriteUsers() -> Observable<[FavoriteUser]> {
        return favoriteService.getFavoriteUserList()
    }
    
    //초성 헤더 / [초성: 리스트] 형식으로 맵핑 + 정렬 처리
    typealias FavoriteUsersDataSource = (firstSymbols: [Character], source: [Character : [FavoriteUser]])
    private func getSortedFavoriteUsers() -> Observable<FavoriteUsersDataSource> {
        return getFavoriteUsers().flatMap { users in
            return Observable.just(FavoriteReactor.getSortedUserNameList(userList: users))
        }
    }
    
    //한글인지 여부 반환
    static func isKoreanWord(word: String) -> Bool {
        // String -> Array
        let arr = Array(word)
        // 정규식 pattern. 한글, 영어, 숫자, 밑줄(_)만 있어야함
        let pattern = "^[가-힣ㄱ-ㅎㅏ-ㅣ]$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            var index = 0
            while index < arr.count { // string 내 각 문자 하나하나 마다 정규식 체크 후 충족하지 못한것은 제거.
                let results = regex.matches(in: String(arr[index]), options: [], range: NSRange(location: 0, length: 1))
                if results.count == 0 {
                    return false
                } else {
                    index += 1
                }
            }
        }
        return true
    }

    //한글 초성 가져오기
    static func getKoreanFirstSymbol(word: String) -> String? {
        let hangul = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
        let octal = word.unicodeScalars[word.unicodeScalars.startIndex].value
        let index = (octal - 0xac00) / 28 / 21
        return hangul[safe: Int(index)]
    }

    //첫글자 가져오기
    static func getFirstSymbol(word: String) -> Character? {
        if isKoreanWord(word: word) == true, let firstSymbol = getKoreanFirstSymbol(word: word) {
            return firstSymbol.first
        }
        return word.first
    }

    static func getSortedUserNameList(userList: [FavoriteUser]) -> FavoriteUsersDataSource {

        // Build Character Set
        var firstSymbols = Set<Character>()

        for user in userList {
            if let userId = user.userId,
                let firstSymbol = getFirstSymbol(word: userId) {
                firstSymbols.insert(firstSymbol)
            }
        }
        
        // Build tableSourse array
        var tableViewSourse: [Character: [FavoriteUser]] = [:]

        for symbol in firstSymbols {
            var users: [FavoriteUser] = []
            for user in userList {
                if let userId = user.userId,
                   symbol == getFirstSymbol(word: userId) {
                    users.append(user)
                }
            }

            tableViewSourse[symbol] = users.sorted(by: { (lhs, rhs) in
                guard let lhsUserId = lhs.userId, let rhsUserId = rhs.userId else { return lhs.id < rhs.id }
                let lhsKorean = isKoreanWord(word: lhsUserId)
                let rhsKorean = isKoreanWord(word: rhsUserId)
                if lhsKorean && !rhsKorean {
                    return true
                } else if !lhsKorean && rhsKorean {
                    return false
                } else if lhsUserId == rhsUserId {
                    return lhs.createdDateAt < rhs.createdDateAt
                } else {
                    return lhsUserId < rhsUserId
                }
            })
        }

        //한글 -> 영어 순서로 초성 정렬
        let sortedSymbols = firstSymbols.sorted(by: { (lhs, rhs) in
            let lhsKorean = isKoreanWord(word: String(lhs))
            let rhsKorean = isKoreanWord(word: String(rhs))
            if lhsKorean && !rhsKorean {
                return true
            } else if !lhsKorean && rhsKorean {
                return false
            } else {
                return lhs < rhs
            }
        })

        return (sortedSymbols, tableViewSourse)
    }
}
