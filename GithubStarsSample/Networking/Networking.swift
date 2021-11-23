//
//  Networking.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Alamofire
import Moya
import RxSwift


typealias SearchNetworking = Networking<SearchAPI>

final class Networking<Target: TargetType>: MoyaProvider<Target> {
    
    init() {
        var finalPlugins: [PluginType] = []
         finalPlugins.append(NetworkLoggerPlugin())
        
        let endpointClosure = { (target: Target) -> Endpoint in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: ["User-Agent": "Secrets.userAgent"])
        }
        
        let session = MoyaProvider<Target>.defaultAlamofireSession()
        session.sessionConfiguration.timeoutIntervalForRequest = 10
        
        super.init(endpointClosure: endpointClosure, session: session, plugins: finalPlugins)
    }
    
    func request(_ target: Target) -> Observable<Response> {
        return rx.request(target).asObservable()    }
}
