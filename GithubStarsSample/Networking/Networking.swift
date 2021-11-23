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
        
        let requestString = "\(target.method.rawValue) \(target.path)"
        let actualRequest = self.rx.request(target)
        
        return actualRequest.asObservable()
            .do(onNext: { response in
                let message = "SUCCESS: \(requestString) (\(response.statusCode))"
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(message)
            }, onError: { error in
                if let response = (error as? MoyaError)?.response {
                    if let jsonObject = try? response.mapJSON(failsOnEmptyData: false) {
                        let message = "FAILURE: \(requestString) (\(response.statusCode))\n\(jsonObject)"
                        print("----------- <\(#file), \(#function), \(#line)> -----------")
                        print(message)
//                        logger.warning(message)
                    } else if let rawString = String(data: response.data, encoding: .utf8) {
                        let message = "FAILURE: \(requestString) (\(response.statusCode))\n\(rawString)"
                        print("----------- <\(#file), \(#function), \(#line)> -----------")
                        print(message)
//                        logger.warning(message)
                    } else {
                        let message = "FAILURE: \(requestString) (\(response.statusCode))"
                        print("----------- <\(#file), \(#function), \(#line)> -----------")
                        print(message)
//                        logger.warning(message)
                    }
                } else {
                    let message = "FAILURE: \(requestString)\n\(error)"
                    print("----------- <\(#file), \(#function), \(#line)> -----------")
                    print(message)
//                    logger.warning(message)
                }
            }, onSubscribed: {
                let message = "REQUEST: \(requestString)"
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(message)
//                logger.debug(message)
            })
    }
}