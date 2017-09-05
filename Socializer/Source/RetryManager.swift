//
//  RetryManager.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper

// MARK: - Retry management

extension Socializer{

    internal func askCredentialsIfNeeded(forError error: Error) -> Observable<Void> {
        if self.shouldAskCredentials(forError: error) == true {
            return self.askCredentials()
        } else {
            return Observable.just()
        }
    }
    
    internal func askCredentials() -> Observable<Void> {
        guard let askCredentialHandler = self.askCredentialHandler else {
            return Observable.just()
        }
        
        return Observable.just()
            .map({ [unowned self] () -> Void in
                self.clearToken()
            })
            .flatMap({ () -> Observable<Void> in
                return askCredentialHandler()
            })
    }
    
    internal func shouldRenewToken(forError error: Error) -> Bool {
        var shouldRenewToken = false
        if case SocializerError.http(httpURLResponse: let httpURLResponse, data: _) = error, httpURLResponse.statusCode == 401 {
            shouldRenewToken = true
        }
        return shouldRenewToken
    }
    
    internal func shouldAskCredentials(forError error: Error) -> Bool {
        var shouldAskCredentials = false
        if case SocializerError.http(httpURLResponse: let httpURLResponse, data: _) = error, httpURLResponse.statusCode == 401 || httpURLResponse.statusCode == 403 {
            shouldAskCredentials = true
        }
        return shouldAskCredentials
    }
    
    internal func sendAutoRetryRequest<T>(_ sendRequestBlock: @escaping () -> Observable<T>, renewTokenFunction: @escaping () -> Observable<Void>) -> Observable<T> {
        return sendRequestBlock()
            .catchError { [unowned self] (error: Error) -> Observable<T> in
                if self.shouldRenewToken(forError: error) {
                    return renewTokenFunction()
                        .do(onError: { [unowned self] error in
                            // Ask for credentials if renew token fail for any reason
                            self.askCredentials()
                                .subscribe()
                                .addDisposableTo(self.disposeBag)
                        })
                        .flatMap(sendRequestBlock)
                } else {
                    throw error
                }
        }
    }
}
